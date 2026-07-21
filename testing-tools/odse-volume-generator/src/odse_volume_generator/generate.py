"""Generate synthetic patients each with one UI-visible investigation.

Hybrid: tablefaker produces the demographic value pool (names, dates); the driver
assigns deterministic keys, picks SRTE codes, computes the OID gate, and writes one
Parquet file per ODSE table. Bulk-load with load.py via OPENROWSET(FORMAT='PARQUET').
"""

from __future__ import annotations

import argparse
import json
import random
import tempfile
from pathlib import Path

import pyarrow as pa
import pyarrow.parquet as pq
import yaml

from . import config as cfgmod
from . import pools
from .keys import KeyAllocator

SUPERUSER = 10009282
TS = "2026-04-01T00:00:00"
_SCHEMA = Path(__file__).parent / "schema" / "patient_values.yaml"

# Per-table column order + kind. "i" -> int64, "s" -> string (varchar/datetime land
# via implicit conversion on INSERT). Column set is the minimal UI-visible spec.
TABLES: dict[str, list[tuple[str, str]]] = {
    "entity": [("entity_uid", "i"), ("class_cd", "s")],
    "person": [
        ("person_uid", "i"), ("local_id", "s"), ("cd", "s"), ("record_status_cd", "s"),
        ("record_status_time", "s"), ("person_parent_uid", "i"), ("first_nm", "s"),
        ("last_nm", "s"), ("version_ctrl_nbr", "i"), ("status_cd", "s"),
        ("status_time", "s"), ("add_time", "s"), ("add_user_id", "i"),
        ("last_chg_time", "s"), ("last_chg_user_id", "i")],
    "person_name": [
        ("person_uid", "i"), ("person_name_seq", "i"), ("first_nm", "s"),
        ("last_nm", "s"), ("nm_use_cd", "s"), ("record_status_cd", "s"),
        ("record_status_time", "s"), ("status_cd", "s"), ("status_time", "s"),
        ("add_time", "s"), ("add_user_id", "i")],
    "act": [("act_uid", "i"), ("class_cd", "s"), ("mood_cd", "s")],
    "public_health_case": [
        ("public_health_case_uid", "i"), ("cd", "s"), ("cd_desc_txt", "s"),
        ("case_type_cd", "s"), ("case_class_cd", "s"), ("record_status_cd", "s"),
        ("record_status_time", "s"), ("investigation_status_cd", "s"),
        ("prog_area_cd", "s"), ("jurisdiction_cd", "s"),
        ("program_jurisdiction_oid", "i"), ("shared_ind", "s"),
        ("version_ctrl_nbr", "i"), ("status_cd", "s"), ("status_time", "s"),
        ("activity_from_time", "s"), ("local_id", "s"), ("add_time", "s"),
        ("add_user_id", "i"), ("last_chg_time", "s"), ("last_chg_user_id", "i")],
    "participation": [
        ("act_uid", "i"), ("subject_entity_uid", "i"), ("type_cd", "s"),
        ("act_class_cd", "s"), ("subject_class_cd", "s"), ("record_status_cd", "s"),
        ("record_status_time", "s"), ("status_cd", "s"), ("status_time", "s"),
        ("add_time", "s"), ("add_user_id", "i"), ("last_chg_time", "s"),
        ("last_chg_user_id", "i"), ("type_desc_txt", "s")],
}


def _value_pool(patients: int, seed: int):
    import tablefaker

    spec = yaml.safe_load(_SCHEMA.read_text())
    spec["config"]["seed"] = seed
    spec["tables"][0]["row_count"] = patients
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as fh:
        yaml.safe_dump(spec, fh)
        path = fh.name
    dfs = tablefaker.to_pandas(path)
    return dfs["patient_values"] if isinstance(dfs, dict) else dfs


def generate(cfg: cfgmod.Config, out_dir: Path) -> dict:
    ka = KeyAllocator(base=cfg.key_base, stride=cfg.key_stride_per_patient)
    rng = random.Random(cfg.seed)
    df = _value_pool(cfg.patients, cfg.seed)

    cols = {t: {c: [] for c, _ in spec} for t, spec in TABLES.items()}
    samples = []

    def add(table, **vals):
        for c, _ in TABLES[table]:
            cols[table][c].append(vals[c])

    for i in range(cfg.patients):
        pt = ka.person_uid(i)
        phc = ka.investigation_uid(i, 0)
        row = df.iloc[i]
        first, last = str(row["first_nm"]), str(row["last_nm"])
        start = str(row["start_date"])[:10]
        cond_cd, prog_cd, cond_nm = rng.choice(pools.CONDITIONS)
        juris_cd, juris_uid = rng.choice(pools.JURISDICTIONS)
        oid = pools.oid(juris_uid, prog_cd)

        add("entity", entity_uid=pt, class_cd="PSN")
        add("person", person_uid=pt, local_id=ka.local_id(pt, "PSN"), cd="PAT",
            record_status_cd="ACTIVE", record_status_time=TS, person_parent_uid=pt,
            first_nm=first, last_nm=last, version_ctrl_nbr=1, status_cd="A",
            status_time=TS, add_time=TS, add_user_id=SUPERUSER, last_chg_time=TS,
            last_chg_user_id=SUPERUSER)
        add("person_name", person_uid=pt, person_name_seq=1, first_nm=first,
            last_nm=last, nm_use_cd="L", record_status_cd="ACTIVE",
            record_status_time=TS, status_cd="A", status_time=TS, add_time=TS,
            add_user_id=SUPERUSER)
        add("act", act_uid=phc, class_cd="CASE", mood_cd="EVN")
        add("public_health_case", public_health_case_uid=phc, cd=cond_cd,
            cd_desc_txt=cond_nm, case_type_cd="I", case_class_cd="C",
            record_status_cd="OPEN", record_status_time=TS, investigation_status_cd="O",
            prog_area_cd=prog_cd, jurisdiction_cd=juris_cd,
            program_jurisdiction_oid=oid, shared_ind="T", version_ctrl_nbr=1,
            status_cd="A", status_time=TS, activity_from_time=start,
            local_id=ka.local_id(phc, "CAS"), add_time=TS, add_user_id=SUPERUSER,
            last_chg_time=TS, last_chg_user_id=SUPERUSER)
        add("participation", act_uid=phc, subject_entity_uid=pt, type_cd="SubjOfPHC",
            act_class_cd="CASE", subject_class_cd="PSN", record_status_cd="ACTIVE",
            record_status_time=TS, status_cd="A", status_time=TS, add_time=TS,
            add_user_id=SUPERUSER, last_chg_time=TS, last_chg_user_id=SUPERUSER,
            type_desc_txt="Subject of Public Health Case")

        if i < 5 or i == cfg.patients - 1:
            samples.append({"idx": i, "last_nm": last, "mpr_uid": pt, "phc_uid": phc,
                            "condition": cond_cd, "jurisdiction": juris_cd, "oid": oid})

    out_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    for t, spec in TABLES.items():
        arrays = {c: pa.array(cols[t][c],
                              type=pa.int64() if k == "i" else pa.string())
                  for c, k in spec}
        table = pa.table(arrays)
        path = out_dir / f"{t}.parquet"
        pq.write_table(table, path)
        written[t] = {"path": str(path), "rows": table.num_rows,
                      "columns": [c for c, _ in spec]}

    manifest = {"patients": cfg.patients, "seed": cfg.seed,
                "key_base": cfg.key_base, "max_uid": ka.max_uid(cfg.patients),
                "tables": written, "samples": samples}
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    return manifest


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="config/ratios.yaml")
    ap.add_argument("--patients", type=int)
    ap.add_argument("--out", default="out")
    args = ap.parse_args()
    cfg = cfgmod.load(args.config)
    if args.patients:
        cfg.patients = args.patients
    m = generate(cfg, Path(args.out))
    total = sum(t["rows"] for t in m["tables"].values())
    print(f"generated {m['patients']} patients -> {total} rows across {len(m['tables'])} "
          f"parquet files in {args.out}, keys {cfg.key_base}..{m['max_uid']}")
    s = m["samples"][0]
    print(f"sample: last_nm={s['last_nm']} mpr={s['mpr_uid']} phc={s['phc_uid']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
