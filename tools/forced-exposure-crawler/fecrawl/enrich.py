"""Attach Apple Music links and representative tracks to crawled releases."""

from __future__ import annotations

import logging
from pathlib import Path

from .applemusic import AppleMusicLookup
from .fetch import Fetcher
from .records import Release
from .tracks import candidate_titles, select_tracks

log = logging.getLogger(__name__)


def enrich(
    releases: list[Release],
    lookup: AppleMusicLookup,
    fetcher: Fetcher,
    *,
    progress_every: int = 25,
) -> dict[str, int]:
    """Fill in apple_url, apple_genre and tracks in place. Returns counts."""
    stats = {
        "linked": 0,
        "unlinked": 0,
        "tracks_from_review": 0,
        "tracks_from_opening": 0,
        "total_tracks": 0,
    }

    for index, release in enumerate(releases, 1):
        match = lookup.find(release.artist, release.title)
        if match is None:
            stats["unlinked"] += 1
        else:
            stats["linked"] += 1
            release.apple_url = match.url
            release.apple_genre = match.genre

            # Track titles come from the write-up but are only kept once they
            # match the album's real tracklist.
            candidates: list[str] = []
            if release.url:
                try:
                    candidates = candidate_titles(fetcher.get(release.url))
                except Exception as exc:  # cached page missing or unreadable
                    log.debug("no description for %s: %s", release.url, exc)

            picked, source = select_tracks(candidates, lookup.tracklist(match.url))
            release.track_source = source
            release.tracks = [
                {"name": t.get("trackName", ""), "url": _track_url(t)} for t in picked
            ]
            stats["total_tracks"] += len(release.tracks)
            if source == "review":
                stats["tracks_from_review"] += 1
            elif source == "opening":
                stats["tracks_from_opening"] += 1

        if index % progress_every == 0:
            log.info("%d/%d enriched", index, len(releases))

    return stats


def _track_url(track: dict) -> str:
    url = track.get("trackViewUrl", "")
    # Keep the ?i= track id, drop only the tracking parameter.
    return url.replace("&uo=4", "").replace("?uo=4", "")
