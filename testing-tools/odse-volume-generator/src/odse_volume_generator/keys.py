"""Deterministic key allocation for the ODSE volume generator.

The driver owns keys; tablefaker owns values. Every UID is a pure function of
(patient_index, subtree_offset), so shards generate independently with no lookups
and no collisions, and a fixed seed reproduces the exact same dataset.

Layout, per patient i, inside a stride-wide block based at `key_base + i*stride`:

    offset 0        person_uid == entity_uid == person_parent_uid (MPR self-ref)
    offset 100+k    investigation k: act_uid == public_health_case_uid
    offset 300+k    the SubjOfPHC participation is keyed on (act_uid, entity_uid), no surrogate
    offset 400+j    observation j: act_uid == observation_uid
    offset 600+j    obs_value rows reuse the observation_uid
    offset 800+t    treatment t
    offset 900+n    notification n

Offsets leave headroom; widen `stride` in ratios.yaml if a subtree outgrows it.
"""

from __future__ import annotations

from dataclasses import dataclass

# Subtree offsets within a patient's block. Keep these below `stride`.
_PERSON = 0
_INVESTIGATION = 100
_PARTICIPATION = 300
_OBSERVATION = 400
_OBS_VALUE = 600
_TREATMENT = 800
_NOTIFICATION = 900


@dataclass(frozen=True)
class KeyAllocator:
    base: int = 100_000_000
    stride: int = 1000

    def block(self, i: int) -> int:
        """First UID of patient i's reserved block."""
        return self.base + i * self.stride

    # One Person per patient in the prototype: person == entity == its own MPR.
    def person_uid(self, i: int) -> int:
        return self.block(i) + _PERSON

    entity_uid = person_uid
    mpr_uid = person_uid

    def investigation_uid(self, i: int, k: int = 0) -> int:
        return self.block(i) + _INVESTIGATION + k

    def observation_uid(self, i: int, j: int) -> int:
        return self.block(i) + _OBSERVATION + j

    def obs_value_uid(self, i: int, j: int) -> int:
        return self.block(i) + _OBS_VALUE + j

    def treatment_uid(self, i: int, t: int) -> int:
        return self.block(i) + _TREATMENT + t

    def notification_uid(self, i: int, n: int) -> int:
        return self.block(i) + _NOTIFICATION + n

    def local_id(self, uid: int, prefix: str = "OBS") -> str:
        """NBS local id, e.g. OBS100000000GA01. Matches the fixture convention."""
        return f"{prefix}{uid}GA01"

    def max_uid(self, patients: int) -> int:
        """Highest UID the run can touch. Assert this stays clear of other ranges."""
        return self.block(patients - 1) + self.stride - 1


def shards(patients: int, per_shard: int):
    """Yield (shard_index, start_patient, count) covering [0, patients)."""
    shard = 0
    start = 0
    while start < patients:
        count = min(per_shard, patients - start)
        yield shard, start, count
        start += count
        shard += 1
