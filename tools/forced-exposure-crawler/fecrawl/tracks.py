"""Pick one representative track per release.

A playlist built from whole albums runs to thousands of tracks; one track per
release keeps it to hundreds. The track is chosen in this order:

  1. a track named in Forced Exposure's own write-up, confirmed against the
     album's real tracklist
  2. the opening track

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


def choose_track(candidates: list[str], tracklist: list[dict]) -> tuple[dict | None, str]:
    """Return (track, source) for a release.

    `source` is "review" when the pick came from a validated mention and
    "opening" when it fell back to track one, so the provenance of every pick
    stays visible rather than being implied.
    """
    if not tracklist:
        return None, "none"

    by_name = {fold(t.get("trackName", "")): t for t in tracklist if t.get("trackName")}
    for candidate in candidates:
        folded = fold(candidate)
        if not folded:
            continue
        if folded in by_name:
            return by_name[folded], "review"
        # A mention may carry a stray article or a partial phrase.
        for name, track in by_name.items():
            if len(folded) >= 6 and (folded in name or name in folded):
                return track, "review"

    ordered = sorted(tracklist, key=lambda t: (t.get("discNumber") or 1, t.get("trackNumber") or 1))
    return ordered[0], "opening"
