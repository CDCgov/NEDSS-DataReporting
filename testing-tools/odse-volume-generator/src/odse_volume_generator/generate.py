"""Generate synthetic patients with the full ODSE business fan-out.

Hybrid: tablefaker produces the demographic value pool (names, dates); the driver
assigns deterministic keys, samples per-patient fan-out from the Poisson ratios
(calibrated to the Kentucky ODSE), and builds a referentially-coherent graph. FKs
on these tables are enforced, so parents (Act, Entity, Person, Observation,
Organization) are materialized before children. Output is one Parquet per table;
bulk-load with load.py via OPENROWSET(FORMAT='PARQUET') in dependency order.
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

# Per-table column order + kind ("i" int64, "s" string). Minimal loadable sets.
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
    "entity_id": [
        ("entity_uid", "i"), ("entity_id_seq", "i"), ("type_cd", "s"),
        ("root_extension_txt", "s"), ("assigning_authority_cd", "s"),
        ("record_status_cd", "s"), ("status_cd", "s"), ("add_time", "s"),
        ("add_user_id", "i")],
    "organization": [
        ("organization_uid", "i"), ("version_ctrl_nbr", "i"), ("display_nm", "s"),
        ("local_id", "s"), ("record_status_cd", "s"), ("status_cd", "s"),
        ("add_time", "s"), ("add_user_id", "i")],
    "organization_name": [
        ("organization_uid", "i"), ("organization_name_seq", "i"), ("nm_txt", "s"),
        ("nm_use_cd", "s"), ("record_status_cd", "s")],
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
    "observation": [
        ("observation_uid", "i"), ("shared_ind", "s"), ("version_ctrl_nbr", "i"),
        ("cd", "s"), ("cd_desc_txt", "s"), ("cd_system_cd", "s"),
        ("obs_domain_cd_st_1", "s"), ("obs_domain_cd", "s"), ("ctrl_cd_display_form", "s"),
        ("subject_person_uid", "i"), ("record_status_cd", "s"),
        ("record_status_time", "s"), ("status_cd", "s"), ("status_time", "s"),
        ("add_time", "s"), ("add_user_id", "i")],
    "obs_value_coded": [
        ("observation_uid", "i"), ("code", "s"), ("code_system_cd", "s"),
        ("display_name", "s")],
    "obs_value_txt": [
        ("observation_uid", "i"), ("obs_value_txt_seq", "i"), ("txt_type_cd", "s"),
        ("value_txt", "s")],
    "obs_value_numeric": [
        ("observation_uid", "i"), ("obs_value_numeric_seq", "i"),
        ("comparator_cd_1", "s"), ("numeric_value_1", "i"), ("numeric_unit_cd", "s")],
    "obs_value_date": [
        ("observation_uid", "i"), ("obs_value_date_seq", "i"), ("from_time", "s")],
    "act_relationship": [
        ("source_act_uid", "i"), ("target_act_uid", "i"), ("type_cd", "s"),
        ("source_class_cd", "s"), ("target_class_cd", "s"), ("sequence_nbr", "i"),
        ("record_status_cd", "s"), ("status_cd", "s"), ("add_time", "s"),
        ("add_user_id", "i")],
    "participation": [
        ("act_uid", "i"), ("subject_entity_uid", "i"), ("type_cd", "s"),
        ("act_class_cd", "s"), ("subject_class_cd", "s"), ("record_status_cd", "s"),
        ("record_status_time", "s"), ("status_cd", "s"), ("status_time", "s"),
        ("add_time", "s"), ("add_user_id", "i")],
}

# Load order: FK parents before children.
LOAD_ORDER = [
    "entity", "act", "person", "organization",
    "person_name", "entity_id", "organization_name", "public_health_case",
    "observation", "obs_value_coded", "obs_value_txt", "obs_value_numeric",
    "obs_value_date", "act_relationship", "participation",
]


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


def generate(cfg: cfgmod.Config, out_dir: Path, shard_idx: int = 0,
             start: int = 0, count: int | None = None) -> dict:
    """Generate patients [start, start+count). Keys are global (deterministic from
    the patient index), so shards never collide. The seed is offset by shard_idx so
    each shard's values differ yet the whole run is reproducible."""
    if count is None:
        count = cfg.patients
    seed = cfg.seed + shard_idx
    ka = KeyAllocator(base=cfg.key_base, stride=cfg.key_stride_per_patient)
    rng = random.Random(seed)
    df = _value_pool(count, seed)
    cols = {t: {c: [] for c, _ in spec} for t, spec in TABLES.items()}
    samples = []

    def add(table, **vals):
        for c, _ in TABLES[table]:
            cols[table][c].append(vals.get(c))

    def n(name, **over):
        return cfg.dist(name).sample(rng)

    for i in range(start, start + count):
        primary = ka.person_uid(i)
        row = df.iloc[i - start]
        first, last = str(row["first_nm"]), str(row["last_nm"])
        activity_dt = str(row["start_date"])[:10]

        n_person = max(1, n("person_records_per_patient"))
        n_org = n("organizations_per_patient")
        n_inv = n("investigations_per_patient")
        n_obs = n("observations_per_patient")

        person_uids = [ka.person_record_uid(i, p) for p in range(n_person)]
        org_uids = [ka.organization_uid(i, o) for o in range(n_org)]
        phc_uids = [ka.investigation_uid(i, k) for k in range(n_inv)]
        obs_uids = [ka.observation_uid(i, j) for j in range(n_obs)]
        entity_uids = person_uids + org_uids
        act_uids = phc_uids + obs_uids

        # Persons (primary p=0 is the searchable PAT and everyone's MPR).
        for p, pu in enumerate(person_uids):
            add("entity", entity_uid=pu, class_cd="PSN")
            add("person", person_uid=pu, local_id=ka.local_id(pu, "PSN"), cd="PAT",
                record_status_cd="ACTIVE", record_status_time=TS, person_parent_uid=primary,
                first_nm=first, last_nm=last, version_ctrl_nbr=1, status_cd="A",
                status_time=TS, add_time=TS, add_user_id=SUPERUSER, last_chg_time=TS,
                last_chg_user_id=SUPERUSER)

        # Person names spread across this patient's person records.
        name_seq = {pu: 0 for pu in person_uids}
        for _ in range(n("person_names_per_patient")):
            pu = person_uids[rng.randrange(n_person)]
            name_seq[pu] += 1
            add("person_name", person_uid=pu, person_name_seq=name_seq[pu],
                first_nm=first, last_nm=last, nm_use_cd="L", record_status_cd="ACTIVE",
                record_status_time=TS, status_cd="A", status_time=TS, add_time=TS,
                add_user_id=SUPERUSER)

        # Organizations (entity ORG -> organization -> organization_name).
        for o, ou in enumerate(org_uids):
            add("entity", entity_uid=ou, class_cd="ORG")
            add("organization", organization_uid=ou, version_ctrl_nbr=1,
                display_nm=f"{last} Laboratory {o}", local_id=ka.local_id(ou, "ORG"),
                record_status_cd="ACTIVE", status_cd="A", add_time=TS, add_user_id=SUPERUSER)
            add("organization_name", organization_uid=ou, organization_name_seq=1,
                nm_txt=f"{last} Laboratory {o}", nm_use_cd="L", record_status_cd="ACTIVE")

        # entity_id rows spread across all this patient's entities.
        eid_seq = {eu: 0 for eu in entity_uids}
        for _ in range(n("entity_ids_per_patient")):
            eu = entity_uids[rng.randrange(len(entity_uids))]
            eid_seq[eu] += 1
            t = rng.choice(pools.ENTITY_ID_TYPES)
            add("entity_id", entity_uid=eu, entity_id_seq=eid_seq[eu], type_cd=t,
                root_extension_txt=f"{t}{rng.randint(10**8, 10**9 - 1)}",
                assigning_authority_cd="CLIA", record_status_cd="ACTIVE", status_cd="A",
                add_time=TS, add_user_id=SUPERUSER)

        # Investigations (act CASE -> public_health_case -> SubjOfPHC to primary).
        for phc in phc_uids:
            cond_cd, prog_cd, cond_nm = rng.choice(pools.CONDITIONS)
            juris_cd, juris_uid = rng.choice(pools.JURISDICTIONS)
            add("act", act_uid=phc, class_cd="CASE", mood_cd="EVN")
            add("public_health_case", public_health_case_uid=phc, cd=cond_cd,
                cd_desc_txt=cond_nm, case_type_cd="I", case_class_cd="C",
                record_status_cd="OPEN", record_status_time=TS, investigation_status_cd="O",
                prog_area_cd=prog_cd, jurisdiction_cd=juris_cd,
                program_jurisdiction_oid=pools.oid(juris_uid, prog_cd), shared_ind="T",
                version_ctrl_nbr=1, status_cd="A", status_time=TS, activity_from_time=activity_dt,
                local_id=ka.local_id(phc, "CAS"), add_time=TS, add_user_id=SUPERUSER,
                last_chg_time=TS, last_chg_user_id=SUPERUSER)
            add("participation", act_uid=phc, subject_entity_uid=primary,
                type_cd="SubjOfPHC", act_class_cd="CASE", subject_class_cd="PSN",
                record_status_cd="ACTIVE", record_status_time=TS, status_cd="A",
                status_time=TS, add_time=TS, add_user_id=SUPERUSER)

        # Observations (act OBS -> observation -> value rows).
        for obs in obs_uids:
            loinc, lname = rng.choice(pools.LOINC)
            add("act", act_uid=obs, class_cd="OBS", mood_cd="EVN")
            add("observation", observation_uid=obs, shared_ind="T", version_ctrl_nbr=1,
                cd=loinc, cd_desc_txt=lname, cd_system_cd="2.16.840.1.113883.6.1",
                obs_domain_cd_st_1="Result", obs_domain_cd="Result",
                ctrl_cd_display_form="LabReport", subject_person_uid=primary,
                record_status_cd="ACTIVE", record_status_time=TS, status_cd="A",
                status_time=TS, add_time=TS, add_user_id=SUPERUSER)
            for c in range(n("obs_value_coded_per_observation")):
                add("obs_value_coded", observation_uid=obs, code=f"C{c}_{loinc}",
                    code_system_cd="2.16.840.1.113883.6.96", display_name="Positive")
            for s in range(n("obs_value_txt_per_observation")):
                add("obs_value_txt", observation_uid=obs, obs_value_txt_seq=s + 1,
                    txt_type_cd="FT", value_txt=f"result narrative {s}")
            for s in range(n("obs_value_numeric_per_observation")):
                add("obs_value_numeric", observation_uid=obs, obs_value_numeric_seq=s + 1,
                    comparator_cd_1=">", numeric_value_1=rng.randint(1, 500),
                    numeric_unit_cd="Index")
            for s in range(n("obs_value_date_per_observation")):
                add("obs_value_date", observation_uid=obs, obs_value_date_seq=s + 1,
                    from_time=TS)

        # act_relationships: link acts of this patient (distinct source,target,type).
        seen_ar = set()
        for _ in range(n("act_relationships_per_patient")):
            if not obs_uids or len(act_uids) < 2:
                break
            src = rng.choice(obs_uids)
            tgt = rng.choice(act_uids)
            if tgt == src:
                continue
            is_case = tgt in phc_uids
            typ = "LabReport" if is_case else "COMP"
            key = (src, tgt, typ)
            if key in seen_ar:
                continue
            seen_ar.add(key)
            add("act_relationship", source_act_uid=src, target_act_uid=tgt, type_cd=typ,
                source_class_cd="OBS", target_class_cd="CASE" if is_case else "OBS",
                sequence_nbr=1, record_status_cd="ACTIVE", status_cd="A", add_time=TS,
                add_user_id=SUPERUSER)

        # participations: link entities to acts (distinct act,entity,type). Leave
        # cd/role_seq NULL to avoid the Role FK.
        seen_part = {(phc, primary, "SubjOfPHC") for phc in phc_uids}
        for _ in range(n("participations_per_patient")):
            if not act_uids or not entity_uids:
                break
            au = rng.choice(act_uids)
            eu = rng.choice(entity_uids)
            typ = rng.choice(pools.PARTICIPATION_TYPES)
            key = (au, eu, typ)
            if key in seen_part:
                continue
            seen_part.add(key)
            add("participation", act_uid=au, subject_entity_uid=eu, type_cd=typ,
                act_class_cd="OBS", subject_class_cd="PSN", record_status_cd="ACTIVE",
                record_status_time=TS, status_cd="A", status_time=TS, add_time=TS,
                add_user_id=SUPERUSER)

        if i < start + 3 or i == start + count - 1:
            samples.append({"idx": i, "last_nm": last, "mpr_uid": primary,
                            "phc_uids": phc_uids, "n_obs": n_obs, "n_person": n_person})

    out_dir.mkdir(parents=True, exist_ok=True)
    written = {}
    for t, spec in TABLES.items():
        arrays = {c: pa.array(cols[t][c], type=pa.int64() if k == "i" else pa.string())
                  for c, k in spec}
        table = pa.table(arrays)
        pq.write_table(table, out_dir / f"{t}.parquet")
        written[t] = {"path": str(out_dir / f"{t}.parquet"), "rows": table.num_rows,
                      "columns": [c for c, _ in spec]}

    manifest = {"patients": count, "shard_idx": shard_idx, "start": start,
                "seed": seed, "key_base": cfg.key_base, "load_order": LOAD_ORDER,
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
    print(f"generated {m['patients']} patients -> {total} rows across {len(m['tables'])} tables")
    for t in LOAD_ORDER:
        print(f"  {t:22} {m['tables'][t]['rows']:>10}  ({m['tables'][t]['rows']/m['patients']:.2f}/patient)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
