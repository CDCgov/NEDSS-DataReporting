#!/usr/bin/env python3
"""build_lineage_columns.py — assemble the lineage column appendix from the
per-cluster slices and add a derived `mapping_kind` classification.

Source of truth: the 8-column TSV slices in lineage/columns/ (one per cluster,
L1-L6 + the G1-G4 gap-fill). This script concatenates them in a fixed order,
derives a 9th column `mapping_kind` from `transform_note` (+ status / odse
source), and emits two artifacts the schema-diff tool can consume:

  lineage/LINEAGE_COLUMNS.tsv    canonical, greppable (tabs never occur in the
                                 data, so no quoting is needed -- which is why
                                 this is TSV and not CSV)
  lineage/LINEAGE_COLUMNS.jsonl  one JSON object per row; line-oriented so it
                                 streams and git-diffs cleanly

`mapping_kind` is a *derived* hint, not hand-maintained, so the rules live here
in one place. Values:

  no-source       no ODSE column feeds it: surrogate/IDENTITY keys, generated
                  dims, runtime-DYNAMIC tables, MasterETL-fed dims, operational
                  log/metric state, literal NULL.
  direct          value relocated unchanged: passthrough, direct projection,
                  dim-join / copied-from-dim. No reshape, no value edit.
  pivot           EAV->columnar reshape (PIVOT/unpivot of an answer/observation
                  row into a column) with NO value edit. Structurally moved,
                  value preserved.
  code-translate  a code is mapped to its description / a different coded
                  representation (codeset lookup / decode), whether or not a
                  pivot also moved it. The stored value's *representation*
                  changes even though the datum is "the same".
  derived         the value is actually computed: substring/concat, aggregate
                  (SUM/COUNT/ROW_NUMBER/MAX outside a pivot), CASE rewrite,
                  type convert/cast, COALESCE/ISNULL fallback, flags, etc.
                  Also the catch-all for INFERRED rows whose exact op the
                  fan-out could not isolate ("composed in guarded SELECT").

Run from testing-tools/synthetic-odse-fixtures/:  python3 scripts/build_lineage_columns.py
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent          # comparison-fixtures/
COLS = ROOT / "lineage" / "columns"
OUT_TSV = ROOT / "lineage" / "LINEAGE_COLUMNS.tsv"
OUT_JSONL = ROOT / "lineage" / "LINEAGE_COLUMNS.jsonl"

# fixed concatenation order: original L1-L6 fan-out, then the G1-G4 gap-fill
SLICES = [
    "L1_labs", "L2_hepatitis", "L3_tb_stdhiv_bmird_var", "L4_covid",
    "L5_people_links_dims", "L6_invrepeat_ldf_dyndm",
    "G1_core_investigation", "G2_tbvar_pam", "G3_pam_dims", "G4_operational",
]

SRC_HEADER = ["rdb_modern_table", "rdb_modern_col", "writing_sp",
              "nrt_staging_source", "odse_source_col(s)", "transform_note",
              "status", "fixture_proof"]
# mapping_kind is inserted right after transform_note
OUT_HEADER = SRC_HEADER[:6] + ["mapping_kind"] + SRC_HEADER[6:]
JSON_KEYS = ["rdb_modern_table", "rdb_modern_col", "writing_sp",
             "nrt_staging_source", "odse_source_cols", "transform_note",
             "mapping_kind", "status", "fixture_proof"]


def classify(odse, note, status):
    """Derive mapping_kind. Order matters: pivots are resolved before the
    aggregate check so a PIVOT's own MAX(answer_txt) is not read as an
    aggregate, and code-translate is checked inside the pivot branch so a
    pivot that also decodes a coded answer is labelled code-translate."""
    s = status.strip().upper()
    src = odse.lower().strip()
    n = note.lower()

    # 1. no ODSE column at all
    if "MASTERETL_ONLY" in s or "DYNAMIC" in s:
        return "no-source"
    if (any(k in src for k in ("surrogate", "no odse", "(none)", "generated",
                               "masteretl", "no static odse", "n/a",
                               "operational"))
            or src in ("", "-", "—")
            or src.startswith(("(material", "(surrogate"))):
        return "no-source"
    if (n.startswith(("literal", "cast null", "getdate"))
            or any(k in n for k in ("surrogate", "identity", "sentinel",
                                    "group surrogate key", "generated"))):
        return "no-source"

    has_codetx = any(k in n for k in (
        "code-translate", "code translate", "code-translat", "coded answer",
        "codeset", "decode", "translate", " code ", "code/", "/code", " desc"))

    # 2. pivot / unpivot family (reshape). value-preserving unless it decodes.
    if "pivot" in n:
        return "code-translate" if has_codetx else "pivot"

    # 3. genuine value computation (no pivot in play)
    if any(k in n for k in (
            "substring", "left(", "right(", "concat", " + ", "row_number",
            "sum(", "count(", "max(", "min(", "avg(", "string_agg", "rollup",
            "calc", "convert", "cast(", " cast", "upper(", "lower(", " trim",
            "format(", "truncat", " flag", "component", " walk", " rn=",
            "earliest", "latest", "isnull", "coalesce", "nullif", "replace",
            "blank-", "->null")):
        return "derived"

    # 4. code->description / codeset lookup without a pivot
    if has_codetx or "lookup" in n:
        return "code-translate"

    # 5. value relocated unchanged
    if (n.strip().startswith("direct")
            or any(k in n for k in (
                "pass-through", "passthrough", "projection", "project",
                "carried", "carry", "copied", "copy", "join", "->", " via ",
                "surfaced", "positional", "reads nrt", "dimensional fk",
                "resolved via"))):
        return "direct"

    # 6. INFERRED rows whose exact op we could not isolate
    return "derived"


def main():
    rows = []
    for name in SLICES:
        path = COLS / f"{name}.tsv"
        if not path.exists():
            sys.exit(f"missing slice: {path}")
        lines = path.read_text().splitlines()
        header = lines[0].split("\t")
        if header != SRC_HEADER:
            sys.exit(f"{name}: unexpected header\n  got: {header}\n  want: {SRC_HEADER}")
        for ln, raw in enumerate(lines[1:], start=2):
            if raw == "":
                continue
            f = raw.split("\t")
            if len(f) != 8:
                sys.exit(f"{name} line {ln}: expected 8 fields, got {len(f)}")
            kind = classify(f[4], f[5], f[6])
            rows.append(f[:6] + [kind] + f[6:])

    with OUT_TSV.open("w") as fh:
        fh.write("\t".join(OUT_HEADER) + "\n")
        for r in rows:
            fh.write("\t".join(r) + "\n")

    with OUT_JSONL.open("w") as fh:
        for r in rows:
            fh.write(json.dumps(dict(zip(JSON_KEYS, r)), ensure_ascii=False) + "\n")

    dist = {}
    for r in rows:
        dist[r[6]] = dist.get(r[6], 0) + 1
    total = len(rows)
    print(f"wrote {OUT_TSV.relative_to(ROOT)} and {OUT_JSONL.relative_to(ROOT)}")
    print(f"{total} rows across {len({r[0].upper() for r in rows})} tables\n")
    print("mapping_kind distribution:")
    for k in ("direct", "pivot", "code-translate", "derived", "no-source"):
        c = dist.get(k, 0)
        print(f"  {k:14s} {c:5d}  ({100*c/total:4.1f}%)")
    leftover = set(dist) - {"direct", "pivot", "code-translate", "derived", "no-source"}
    if leftover:
        sys.exit(f"unexpected mapping_kind values: {leftover}")


if __name__ == "__main__":
    main()
