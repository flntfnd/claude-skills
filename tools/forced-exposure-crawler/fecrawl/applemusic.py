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
import re
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


def artist_variants(artist: str) -> list[str]:
    """Plausible readings of an FE artist credit, best guess first.

    FE stores credits in inverted library order and in capitals, so about half
    the catalog reads "FURY, BILLY". A comma is not proof of inversion though:
    "TRAD, GRAS OCH STENAR" is the band's actual name, while
    "DE ANGELIS, GUIDO & MAURIZIO" really is inverted, and both carry three
    words after the comma. Rather than guess, offer both readings and let the
    match against real Apple Music metadata decide which one exists.
    """
    artist = artist.strip()
    variants: list[str] = [artist]

    without_paren = re.sub(r"\s*\([^)]*\)", "", artist).strip()
    if without_paren and without_paren != artist:
        variants.append(without_paren)

    for base in list(variants):
        head, sep, tail = base.partition(",")
        if sep and head.strip() and tail.strip():
            variants.append(f"{tail.strip()} {head.strip()}")
    return list(dict.fromkeys(v for v in variants if v))


def _title_variants(title: str) -> set[str]:
    """Comparison forms for a title, with and without an edition suffix."""
    base = strip_format_suffixes(title)
    return {fold(title), fold(base)}


def _is_match(release_artist: str, release_title: str, result: dict) -> bool:
    got_artist = normalize_artist(result.get("artistName", ""))
    if not got_artist:
        return False
    wanted = [normalize_artist(v) for v in artist_variants(release_artist)]
    # One side may carry extra members ("Albert Ayler" vs "Albert Ayler Trio").
    if not any(
        want and (got_artist in want or want in got_artist) for want in wanted
    ):
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

    def _search(self, term: str, entity: str = "album") -> list[dict]:
        cached = self._cache_path(term if entity == "album" else f"{entity}:{term}")
        if cached.exists():
            return json.loads(cached.read_text(encoding="utf-8")).get("results", [])
        if self.offline:
            return []

        params = {
            "term": term,
            "entity": entity,
            "limit": 12 if entity == "album" else 200,
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

    def tracklist(self, album_url: str, artist: str = "", title: str = "") -> list[dict]:
        """Tracks of an album, given its Apple Music URL.

        The album id is the trailing path component of the URL; the lookup
        endpoint returns the album followed by its tracks.
        """
        album_id = album_url.rstrip("/").rsplit("/", 1)[-1]
        if not album_id.isdigit():
            return []

        cached = self._cache_path(f"lookup:{album_id}")
        if cached.exists():
            payload = json.loads(cached.read_text(encoding="utf-8"))
        elif self.offline:
            return []
        else:
            params = {"id": album_id, "entity": "song", "limit": 200}
            self._throttle()
            try:
                response = self._session.get(
                    f"https://itunes.apple.com/lookup?{urlencode(params)}",
                    timeout=self.timeout,
                )
                if not response.ok:
                    return []
                payload = response.json()
                cached.write_text(json.dumps(payload), encoding="utf-8")
            except (requests.RequestException, ValueError) as exc:
                log.warning("iTunes tracklist error for %s: %s", album_id, exc)
                return []

        tracks = [
            r for r in payload.get("results", []) if r.get("wrapperType") == "track"
        ]
        if tracks or not (artist or title):
            return tracks

        # Some albums come back from the lookup endpoint as a collection with a
        # real trackCount but no track entities, which happens when the tracks
        # are not individually available in this storefront. Searching the song
        # entity and keeping only this album's tracks recovers them.
        wanted = str(album_id)
        found = [
            r
            for r in self._search(f"{artist} {title}".strip(), entity="song")
            if str(r.get("collectionId")) == wanted
        ]
        return sorted(
            found, key=lambda t: (t.get("discNumber") or 1, t.get("trackNumber") or 1)
        )

    def find(self, artist: str, title: str) -> AppleMatch | None:
        clean_title = strip_format_suffixes(title)

        # "VA" is FE's code for a various-artists compilation. There is no
        # artist to match on, so the title carries the match alone, and it must
        # be exact: without the artist check the looser prefix rule would let
        # unrelated records through.
        if normalize_artist(artist) == "various artists":
            want = fold(clean_title)
            for result in self._search(clean_title):
                if want and fold(result.get("collectionName", "")) == want:
                    url = _strip_tracking(result.get("collectionViewUrl", ""))
                    if url:
                        return AppleMatch(
                            url=url,
                            artist=result.get("artistName", ""),
                            album=result.get("collectionName", ""),
                            genre=result.get("primaryGenreName", ""),
                        )
            return None
        for variant in artist_variants(artist):
            for result in self._search(f"{variant} {clean_title}".strip()):
                if _is_match(artist, title, result):
                    url = _strip_tracking(result.get("collectionViewUrl", ""))
                    if url:
                        return AppleMatch(
                            url=url,
                            # Apple's spelling is properly cased and ordered,
                            # so it is the better name to display.
                            artist=result.get("artistName", ""),
                            album=result.get("collectionName", ""),
                            genre=result.get("primaryGenreName", ""),
                        )
        return None
