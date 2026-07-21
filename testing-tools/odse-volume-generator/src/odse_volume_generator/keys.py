"""Deterministic key allocation for the ODSE volume generator.

The driver owns keys; tablefaker owns values. Every UID is a pure function of
(patient_index, subtree_offset), so shards generate independently with no lookups
and no collisions, and a fixed seed reproduces the exact same dataset.

Layout per patient i, inside a stride-wide block based at `key_base + i*stride`:

    0..49     person records (person_uid); p=0 is the primary searchable PAT and
              its own MPR/entity. The rest share person_parent_uid = the primary.
    100..149  investigations: act_uid == public_health_case_uid
    200..249  organizations: entity_uid for org rows (labs, facilities)
    300..799  observations: act_uid == observation_uid
    800..899  misc acts (treatment, notification, intervention)
    900..999  headroom

Tables keyed by (reference, seq) - obs_value_*, entity_id, act_relationship,
participation - consume no block UID; they point at the UIDs above plus a seq.
Widen `stride` in ratios.yaml if a subtree's Poisson tail outgrows its range.
"""

from __future__ import annotations

from dataclasses import dataclass

_PERSON = 0
_INVESTIGATION = 100
_ORGANIZATION = 200
_OBSERVATION = 300
_MISC_ACT = 800


@dataclass(frozen=True)
class KeyAllocator:
    base: int = 100_000_000
    stride: int = 1000

    def block(self, i: int) -> int:
        return self.base + i * self.stride

    def person_record_uid(self, i: int, p: int = 0) -> int:
        return self.block(i) + _PERSON + p

    # The primary Person record is the patient's entity and its own MPR.
    def person_uid(self, i: int) -> int:
        return self.person_record_uid(i, 0)

    entity_uid = person_uid
    mpr_uid = person_uid

    def investigation_uid(self, i: int, k: int = 0) -> int:
        return self.block(i) + _INVESTIGATION + k

    def organization_uid(self, i: int, o: int) -> int:
        return self.block(i) + _ORGANIZATION + o

    def observation_uid(self, i: int, j: int) -> int:
        return self.block(i) + _OBSERVATION + j

    def misc_act_uid(self, i: int, m: int) -> int:
        return self.block(i) + _MISC_ACT + m

    def local_id(self, uid: int, prefix: str = "OBS") -> str:
        return f"{prefix}{uid}GA01"

    def max_uid(self, patients: int) -> int:
        return self.block(patients - 1) + self.stride - 1


def shards(patients: int, per_shard: int):
    """Yield (shard_index, start_patient, count) covering [0, patients)."""
    shard, start = 0, 0
    while start < patients:
        count = min(per_shard, patients - start)
        yield shard, start, count
        start += count
        shard += 1
