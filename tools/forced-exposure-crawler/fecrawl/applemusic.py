"""Resolve releases to Apple Music album links via the public iTunes Search API.

No account or key is required. Results are cached on disk so a re-run costs
nothing and puts no further load on the API.

Matching is strict on artist and title. A plausible-but-wrong album link is
worse than no link, so an entry that does not match cleanly is left unlinked
and reported rather than guessed at.
"""

from __future__ import annotations

import hashlib
import json
import logging
import random
import time
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlencode

import requests

from .normalize import fold, normalize_artist, strip_format_suffixes

log = logging.getLogger(__name__)

SEARCH_URL = "https://itunes.apple.com/search"
# The public API tolerates roughly 20 calls a minute.
DEFAULT_DELAY = 3.0


@dataclass(slots=True)
class AppleMatch:
    url: str
    artist: str
    album: str
    genre: str


def _strip_tracking(url: str) -> str:
    return url.split("?")[0]


def _title_variants(title: str) -> set[str]:
    """Comparison forms for a title, with and without an edition suffix."""
    base = strip_format_suffixes(title)
    return {fold(title), fold(base)}


def _is_match(release_artist: str, release_title: str, result: dict) -> bool:
    got_artist = normalize_artist(result.get("artistName", ""))
    want_artist = normalize_artist(release_artist)
    if not got_artist or not want_artist:
        return False
    # One may carry extra members ("Albert Ayler" vs "Albert Ayler Trio").
    if not (got_artist in want_artist or want_artist in got_artist):
        return False

    got_titles = _title_variants(result.get("collectionName", ""))
    want_titles = _title_variants(release_title)
    return any(
        g and w and (g == w or g.startswith(w) or w.startswith(g))
        for g in got_titles
        for w in want_titles
    )


class AppleMusicLookup:
    def __init__(
        self,
        cache_dir: Path,
        *,
        delay: float = DEFAULT_DELAY,
        timeout: float = 20.0,
        country: str = "US",
        offline: bool = False,
    ) -> None:
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.delay = delay
        self.timeout = timeout
        self.country = country
        self.offline = offline
        self._last = 0.0
        self._session = requests.Session()
        self._session.headers.update({"Accept": "application/json"})

    def _cache_path(self, term: str) -> Path:
        digest = hashlib.sha256(f"{self.country}:{term}".encode()).hexdigest()[:32]
        return self.cache_dir / f"am-{digest}.json"

    def _throttle(self) -> None:
        wait = self.delay + random.uniform(0, 0.4) - (time.monotonic() - self._last)
        if wait > 0:
            time.sleep(wait)
        self._last = time.monotonic()

    def _search(self, term: str) -> list[dict]:
        cached = self._cache_path(term)
        if cached.exists():
            return json.loads(cached.read_text(encoding="utf-8")).get("results", [])
        if self.offline:
            return []

        params = {
            "term": term,
            "entity": "album",
            "limit": 12,
            "country": self.country,
        }
        for attempt in range(4):
            self._throttle()
            try:
                response = self._session.get(
                    f"{SEARCH_URL}?{urlencode(params)}", timeout=self.timeout
                )
                if response.ok:
                    payload = response.json()
                    cached.write_text(json.dumps(payload), encoding="utf-8")
                    return payload.get("results", [])
                if response.status_code not in (403, 429, 500, 502, 503):
                    log.warning("iTunes HTTP %s for %r", response.status_code, term)
                    return []
            except (requests.RequestException, ValueError) as exc:
                log.warning("iTunes error for %r: %s", term, exc)
            time.sleep(min(2**attempt, 16) + random.uniform(0, 1))
        return []

    def find(self, artist: str, title: str) -> AppleMatch | None:
        term = f"{artist} {strip_format_suffixes(title)}".strip()
        for result in self._search(term):
            if _is_match(artist, title, result):
                url = _strip_tracking(result.get("collectionViewUrl", ""))
                if url:
                    return AppleMatch(
                        url=url,
                        artist=result.get("artistName", ""),
                        album=result.get("collectionName", ""),
                        genre=result.get("primaryGenreName", ""),
                    )
        return None
