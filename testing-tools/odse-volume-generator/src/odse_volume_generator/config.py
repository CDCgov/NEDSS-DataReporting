"""Load ratios.yaml and sample the configurable fan-out distributions."""

from __future__ import annotations

import random
from dataclasses import dataclass
from pathlib import Path

import yaml


@dataclass
class Dist:
    """A configurable count: fixed | uniform | zipf over [min,max]."""

    distribution: str = "fixed"
    value: int = 1
    min: int = 1
    max: int = 1
    zipf_param: float = 2.0

    def sample(self, rng: random.Random) -> int:
        if self.distribution == "fixed":
            return self.value
        if self.distribution == "uniform":
            return rng.randint(self.min, self.max)
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
    "observations_per_patient",
    "obs_values_per_result",
    "act_relationships_per_act",
    "participations_per_act",
    "treatments_per_patient",
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
