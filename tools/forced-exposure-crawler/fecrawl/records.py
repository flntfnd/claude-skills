"""The record shape every stage of the pipeline passes around."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field, fields
from typing import Any, Iterable, Iterator


@dataclass(slots=True)
class Release:
    """One catalog entry as it appears on a Forced Exposure product page."""

    artist: str
    title: str
    genre: str = ""
    label: str = ""
    catalog_no: str = ""
    url: str = ""
    formats: list[str] = field(default_factory=list)
    sources: list[str] = field(default_factory=list)

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, sort_keys=True)

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> "Release":
        known = {f.name for f in fields(cls)}
        return cls(**{k: v for k, v in raw.items() if k in known})


def write_jsonl(path: str, releases: Iterable[Release]) -> int:
    count = 0
    with open(path, "w", encoding="utf-8") as handle:
        for release in releases:
            handle.write(release.to_json() + "\n")
            count += 1
    return count


def read_jsonl(path: str) -> Iterator[Release]:
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                yield Release.from_dict(json.loads(line))
