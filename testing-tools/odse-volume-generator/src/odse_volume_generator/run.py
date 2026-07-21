"""Sharded, parallel generation + load.

Generation is embarrassingly parallel: the deterministic range-partitioned key
scheme means shard S owns patients [start, start+count) and computes all its own
UIDs with no shared state. Each worker process generates its shard, writes Parquet,
and frees the memory, so RAM stays flat at O(shard_size) regardless of the total.
Loads run after, in FK-safe order per shard, each staged under its own path.
"""

from __future__ import annotations

import argparse
import multiprocessing as mp
import time
from pathlib import Path

from . import config as cfgmod
from . import generate as gen
from . import keys
from . import load as loadmod


def _gen_worker(spec):
    config_path, out_root, shard_idx, start, count = spec
    cfg = cfgmod.load(config_path)
    out = Path(out_root) / f"shard_{shard_idx:04d}"
    m = gen.generate(cfg, out, shard_idx=shard_idx, start=start, count=count)
    rows = sum(t["rows"] for t in m["tables"].values())
    return {"shard": shard_idx, "start": start, "count": count,
            "manifest": str(out / "manifest.json"), "rows": rows}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="config/ratios.yaml")
    ap.add_argument("--patients", type=int, help="override total patient count")
    ap.add_argument("--out", default="out")
    ap.add_argument("--workers", type=int, default=max(1, mp.cpu_count() - 1))
    ap.add_argument("--no-load", action="store_true", help="generate only, skip DB load")
    args = ap.parse_args()

    cfg = cfgmod.load(args.config)
    patients = args.patients or cfg.patients
    shard_specs = [(args.config, args.out, si, start, count)
                   for si, start, count in keys.shards(patients, cfg.patients_per_shard)]

    print(f"{patients} patients -> {len(shard_specs)} shards of {cfg.patients_per_shard}, "
          f"{args.workers} workers")

    t0 = time.time()
    with mp.Pool(args.workers) as pool:
        results = pool.map(_gen_worker, shard_specs)
    total_rows = sum(r["rows"] for r in results)
    print(f"generated {total_rows} rows in {time.time() - t0:.1f}s "
          f"({total_rows / max(1, time.time() - t0):.0f} rows/s)")

    if args.no_load:
        return 0

    t1 = time.time()
    loaded = 0
    for r in sorted(results, key=lambda x: x["shard"]):
        res = loadmod.load(Path(r["manifest"]), stage_suffix=str(r["shard"]))
        if not all(x["rc"] == 0 for x in res.values()):
            print(f"  shard {r['shard']} LOAD FAILED")
            return 1
        loaded += r["rows"]
        print(f"  shard {r['shard']:>4} loaded ({r['rows']} rows)")
    print(f"loaded {loaded} rows in {time.time() - t1:.1f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
