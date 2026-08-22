"""Pick one representative track per release.

A playlist built from whole albums runs to thousands of tracks; taking only the
tracks a write-up actually points at keeps it to hundreds. Selection is:

  1. every track named in Forced Exposure's own write-up, confirmed against the
     album's real tracklist, however many that is
  2. failing any such mention, the opening track alone

Only track *titles* are read from the write-up, never its prose, and a title is
only accepted once it matches an actual track on the album. That check is what
makes this safe: quoted text in a review is mostly ordinary phrasing, and
without validation roughly half the "tracks" extracted would be wrong.
"""

from __future__ import annotations

import re

from bs4 import BeautifulSoup

from .normalize import fold

# Quoted spans and italics are the two ways a track title tends to be set off.
_QUOTED_RE = re.compile(r'["“”]([^"“”]{2,70})["“”]')

# Only a guard against quoting a whole paragraph. It is deliberately loose:
# titles in this catalog do run long (one Keiji Haino title is thirteen words),
# and every candidate is validated against the real tracklist anyway, so a
# surplus candidate costs nothing while a discarded true title costs a pick.
_MAX_CANDIDATE_WORDS = 20


def candidate_titles(html: str) -> list[str]:
    """Possible track titles mentioned in a product description."""
    soup = BeautifulSoup(html, "lxml")
    desc = soup.select_one(".prod-desc")
    if desc is None:
        return []

    found: list[str] = []
    for tag in desc.find_all(["i", "em"]):
        text = tag.get_text(" ").strip()
        if text:
            found.append(text)
    found.extend(_QUOTED_RE.findall(desc.get_text(" ")))

    cleaned: list[str] = []
    for candidate in found:
        # Reviews quote mid-sentence, so trailing punctuation rides along.
        candidate = candidate.strip().strip(",.;:!?—–-").strip()
        if candidate and len(candidate.split()) <= _MAX_CANDIDATE_WORDS:
            cleaned.append(candidate)
    return cleaned


def select_tracks(
    candidates: list[str], tracklist: list[dict]
) -> tuple[list[dict], str]:
    """Return (tracks, source) for a release.

    Every validated mention is kept, so a write-up that singles out six tracks
    contributes six. `source` is "review" when the picks came from validated
    mentions and "opening" when nothing matched and track one stood in, so the
    provenance of each entry stays visible rather than implied.
    """
    if not tracklist:
        return [], "none"

    by_name = {fold(t.get("trackName", "")): t for t in tracklist if t.get("trackName")}

    matched: dict[int, dict] = {}
    for candidate in candidates:
        folded = fold(candidate)
        if not folded:
            continue
        track = by_name.get(folded)
        if track is None:
            # A mention may carry a stray article or be a partial phrase.
            for name, option in by_name.items():
                if len(folded) >= 6 and (folded in name or name in folded):
                    track = option
                    break
        if track is not None:
            # Keyed by identity so the same track named twice counts once.
            matched[id(track)] = track

    if matched:
        return _in_album_order(matched.values()), "review"
    return _in_album_order(tracklist)[:1], "opening"


def _in_album_order(tracks) -> list[dict]:
    return sorted(
        tracks, key=lambda t: (t.get("discNumber") or 1, t.get("trackNumber") or 1)
    )
