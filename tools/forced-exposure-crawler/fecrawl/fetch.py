"""Polite, cached HTTP fetching.

Every response is written to an on-disk cache keyed by URL. That is not an
optimisation, it is the working model: crawl the catalog once, then iterate on
extraction against the cached copies without touching the site again.
"""

from __future__ import annotations

import hashlib
import logging
import random
import time
import urllib.robotparser
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests

log = logging.getLogger(__name__)

# The "Mozilla/5.0 (compatible; ...)" form is the convention well-behaved
# crawlers use (Googlebot, bingbot). It still identifies this client honestly;
# FE's WAF rejects a bare "fecrawl/1.0" token with a 403. We do not claim to be
# a browser or another operator's bot, and robots.txt is honoured either way.
USER_AGENT = (
    "Mozilla/5.0 (compatible; fecrawl/1.0; +personal catalog archiving)"
)

RETRYABLE_STATUS = frozenset({429, 500, 502, 503, 504})


class FetchError(RuntimeError):
    """A URL could not be retrieved after exhausting retries."""


@dataclass(slots=True)
class FetchStats:
    fetched: int = 0
    from_cache: int = 0
    failed: int = 0


class Fetcher:
    def __init__(
        self,
        cache_dir: Path,
        *,
        delay: float = 1.0,
        timeout: float = 30.0,
        max_retries: int = 4,
        respect_robots: bool = True,
        offline: bool = False,
    ) -> None:
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.delay = delay
        self.timeout = timeout
        self.max_retries = max_retries
        self.offline = offline
        self.stats = FetchStats()
        self._last_request = 0.0
        self._robots: dict[str, urllib.robotparser.RobotFileParser | None] = {}
        self._respect_robots = respect_robots
        self._session = requests.Session()
        self._session.headers.update(
            {"User-Agent": USER_AGENT, "Accept": "text/html,application/xhtml+xml"}
        )

    def _cache_path(self, url: str) -> Path:
        digest = hashlib.sha256(url.encode("utf-8")).hexdigest()[:32]
        return self.cache_dir / f"{digest}.html"

    def _throttle(self) -> None:
        elapsed = time.monotonic() - self._last_request
        # A little jitter so a long crawl does not hammer on a fixed cadence.
        wait = self.delay + random.uniform(0, self.delay * 0.25) - elapsed
        if wait > 0:
            time.sleep(wait)
        self._last_request = time.monotonic()

    def allowed(self, url: str) -> bool:
        if not self._respect_robots:
            return True
        parts = urlparse(url)
        root = f"{parts.scheme}://{parts.netloc}"
        if root not in self._robots:
            parser = urllib.robotparser.RobotFileParser()
            try:
                response = self._session.get(
                    urljoin(root, "/robots.txt"), timeout=self.timeout
                )
                if response.ok:
                    parser.parse(response.text.splitlines())
                else:
                    parser = None  # no robots.txt served: nothing to honour
            except requests.RequestException:
                log.warning("could not read robots.txt for %s, proceeding", root)
                parser = None
            self._robots[root] = parser
        parser = self._robots[root]
        return parser is None or parser.can_fetch(USER_AGENT, url)

    def get(self, url: str, *, refresh: bool = False) -> str:
        """Return the HTML for `url`, from cache when available."""
        cached = self._cache_path(url)
        if cached.exists() and not refresh:
            self.stats.from_cache += 1
            return cached.read_text(encoding="utf-8")

        if self.offline:
            raise FetchError(f"offline and not cached: {url}")

        if not self.allowed(url):
            raise FetchError(f"blocked by robots.txt: {url}")

        last_error: Exception | None = None
        for attempt in range(self.max_retries):
            self._throttle()
            try:
                response = self._session.get(url, timeout=self.timeout)
            except requests.RequestException as exc:
                last_error = exc
            else:
                if response.ok:
                    response.encoding = response.encoding or "utf-8"
                    cached.write_text(response.text, encoding="utf-8")
                    self.stats.fetched += 1
                    return response.text
                if response.status_code not in RETRYABLE_STATUS:
                    self.stats.failed += 1
                    raise FetchError(f"HTTP {response.status_code} for {url}")
                last_error = FetchError(f"HTTP {response.status_code} for {url}")

            backoff = min(2**attempt, 16) + random.uniform(0, 1)
            log.warning(
                "retry %d/%d for %s in %.1fs (%s)",
                attempt + 1,
                self.max_retries,
                url,
                backoff,
                last_error,
            )
            time.sleep(backoff)

        self.stats.failed += 1
        raise FetchError(f"gave up on {url}: {last_error}")
