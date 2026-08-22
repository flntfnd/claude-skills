"""Merge crawled releases into the existing Craft list and render it back out.

The existing list is the source of truth for entries the crawl does not
rediscover (deleted catalog pages, out-of-print stock), so a merge never drops
a line that is already there. It only adds new releases and fills in genres.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Iterable, Sequence

from .normalize import dedupe_key, fold
from .records import Release

# "- [ARTIST — Title](url) (CATNO)" and the plainer "- ARTIST — Title".
_LINKED_RE = re.compile(r"^\s*[-*+]\s*\[(?P<body>.+?)\]\((?P<url>[^)]*)\)\s*(?:\((?P<cat>[^)]*)\))?\s*$")
_PLAIN_RE = re.compile(r"^\s*[-*+]\s*(?P<body>.+?)\s*$")
_SPLIT_RE = re.compile(r"\s+[—–]\s+|\s+-\s+")


@dataclass(slots=True)
class MergeResult:
    entries: list[Release] = field(default_factory=list)
    added: int = 0
    genres_filled: int = 0
    duplicates_collapsed: int = 0
    missing_genre: int = 0


def parse_existing(text: str) -> list[Release]:
    """Read the bullet lines of an exported Craft list into Releases."""
    releases: list[Release] = []
    for raw in text.splitlines():
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith(("#", ">")):
            continue
        url = catalog_no = ""
        match = _LINKED_RE.match(line)
        if match:
            body, url = match.group("body"), match.group("url")
            catalog_no = (match.group("cat") or "").strip()
        else:
            match = _PLAIN_RE.match(line)
            if not match:
                continue
            body = match.group("body")
        parts = _SPLIT_RE.split(body, maxsplit=1)
        if len(parts) != 2:
            continue
        artist, title = parts[0].strip(), parts[1].strip()
        if artist and title:
            releases.append(
                Release(
                    artist=artist,
                    title=title,
                    url=url,
                    catalog_no=catalog_no,
                    sources=["craft"],
                )
            )
    return releases


def _merge_one(into: Release, other: Release) -> int:
    """Fold `other` into `into`. Returns 1 if this filled a missing genre."""
    filled = 0
    if not into.genre and other.genre:
        into.genre = other.genre
        filled = 1
    for attr in ("label", "catalog_no", "url"):
        if not getattr(into, attr) and getattr(other, attr):
            setattr(into, attr, getattr(other, attr))
    for fmt in other.formats:
        if fmt not in into.formats:
            into.formats.append(fmt)
    for source in other.sources:
        if source not in into.sources:
            into.sources.append(source)
    # Prefer the longer artist credit; it is usually the fuller one.
    if len(other.artist) > len(into.artist):
        into.artist = other.artist
    return filled


def merge(existing: Sequence[Release], crawled: Iterable[Release]) -> MergeResult:
    result = MergeResult()
    index: dict[tuple[str, str], Release] = {}

    for release in existing:
        key = dedupe_key(release.artist, release.title)
        if key in index:
            result.duplicates_collapsed += 1
            _merge_one(index[key], release)
        else:
            index[key] = release

    for release in crawled:
        if not release.sources:
            release.sources = ["forcedexposure"]
        key = dedupe_key(release.artist, release.title)
        if key in index:
            result.duplicates_collapsed += 1
            result.genres_filled += _merge_one(index[key], release)
        else:
            index[key] = release
            result.added += 1

    result.entries = sorted(
        index.values(), key=lambda r: dedupe_key(r.artist, r.title)
    )
    result.missing_genre = sum(1 for r in result.entries if not r.genre)
    return result


def _genre_text(release: Release) -> str:
    """FE's coarse bucket, refined by Apple's genre when it adds something."""
    fe = (release.genre or "").strip()
    apple = (release.apple_genre or "").strip()
    if fe and apple and fold(apple) != fold(fe):
        return f"{fe} / {apple}"
    return fe or apple or "Unknown"


def render(
    entries: Sequence[Release],
    *,
    genre_line: bool = True,
    track_line: bool = True,
) -> str:
    """Render entries as Craft markdown, one genre line per entry.

    The headline links to Apple Music when the release resolved there and to
    the catalog page otherwise, so every entry carries a working link.
    """
    lines: list[str] = []
    for release in entries:
        label = f"{release.artist} — {release.title}"
        link = release.apple_url or release.url
        head = f"[{label}]({link})" if link else label
        if release.catalog_no:
            head = f"{head} ({release.catalog_no})"
        lines.append(f"- {head}")

        if genre_line:
            lines.append(f"  - Genre: {_genre_text(release)}")

        if track_line and release.tracks:
            rendered = ", ".join(
                f"[{t['name']}]({t['url']})" if t.get("url") else t["name"]
                for t in release.tracks
            )
            # Say plainly when the track is a stand-in rather than a pick.
            suffix = "" if release.track_source == "review" else " (opening track)"
            lines.append(f"  - Tracks{suffix}: {rendered}")
    return "\n".join(lines)
