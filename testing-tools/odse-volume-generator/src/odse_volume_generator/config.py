"""Load ratios.yaml and sample the configurable fan-out distributions."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass
class Dist:
    """A configurable count: fixed | uniform | zipf over [min,max] | poisson(mean).

    poisson takes a measured per-patient mean directly and gets the total volume
    right (sum over patients = mean * N), which is what the footprint target needs.
    Use it with the ratios measured from a real STLT ODSE. zipf is for when the
    per-patient shape matters more than the total.
    """

    distribution: str = "fixed"
    value: int = 1
    min: int = 1
    max: int = 1
    zipf_param: float = 2.0
    mean: float = 0.0

    def sample(self, rng: random.Random) -> int:
        if self.distribution == "fixed":
            return self.value
        if self.distribution == "uniform":
            return rng.randint(self.min, self.max)
        if self.distribution == "poisson":
            # Knuth. Means here are small (< 25), so this is fine.
            L, k, p = math.exp(-self.mean), 0, 1.0
            while True:
                k += 1
                p *= rng.random()
                if p <= L:
                    return k - 1
        if self.distribution == "zipf":
            # Truncated zipf over the span. Higher zipf_param skews toward min,
            # so most patients get few and a long tail gets many.
            span = self.max - self.min + 1
            weights = [1.0 / (r ** self.zipf_param) for r in range(1, span + 1)]
            return self.min + rng.choices(range(span), weights=weights, k=1)[0]
        raise ValueError(f"unknown distribution: {self.distribution}")


@dataclass
class Config:
    patients: int
    seed: int
    key_base: int
    key_stride_per_patient: int
    patients_per_shard: int
    db: dict
    ratios: dict  # name -> Dist

    def dist(self, name: str) -> Dist:
        return self.ratios[name]


_DIST_KEYS = {
    "investigations_per_patient",
    "person_records_per_patient",
    "person_names_per_patient",
    "entity_ids_per_patient",
    "organizations_per_patient",
    "observations_per_patient",
    "obs_value_txt_per_observation",
    "obs_value_numeric_per_observation",
    "obs_value_coded_per_observation",
    "obs_value_date_per_observation",
    "act_relationships_per_patient",
    "participations_per_patient",
    "treatments_per_investigation",
    "notifications_per_patient",
}


def load(path: str | Path) -> Config:
    raw = yaml.safe_load(Path(path).read_text())
    ratios = {k: Dist(**raw[k]) for k in _DIST_KEYS if k in raw}
    return Config(
        patients=raw["patients"],
        seed=raw["seed"],
        key_base=raw["key_base"],
        key_stride_per_patient=raw["key_stride_per_patient"],
        patients_per_shard=raw["patients_per_shard"],
        db=raw.get("db", {}),
        ratios=ratios,
    )
