"""Resolve existing list entries to catalog URLs using the sitemap.

FE disallows /SearchResult.html in robots.txt, so the site's own search is off
limits. The sitemap is the sanctioned alternative: its product URLs embed an
artist-title-format slug, which is enough to match an "Artist — Title" line
back to its catalog page and pick up that release's genre.

Matching is deliberately strict. Every token of the entry must appear in the
slug, and among the candidates that qualify the one with the fewest surplus
tokens wins. A wrong match would attach a wrong genre, which is worse than
leaving the genre unknown.
"""

from __future__ import annotations

import re
import unicodedata
from urllib.parse import urlparse

from .normalize import strip_format_suffixes

# Format tokens that FE appends to a slug; not part of the release identity.
_SLUG_FORMAT_TAIL = frozenset(
    """
    lp lps ep cd cds cdr dvd bluray 2lp 3lp 4lp 5lp 2cd 3cd 4cd 5cd 6cd
    7 10 12 box cassette tape mc k7 book mag dl digital
    """.split()
)


def slug_tokens(text: str) -> list[str]:
    decomposed = unicodedata.normalize("NFKD", text)
    ascii_only = "".join(c for c in decomposed if not unicodedata.combining(c))
    raw = [t for t in re.split(r"[^0-9a-zA-Z]+", ascii_only.lower()) if t]

    tokens: list[str] = []
    i = 0
    while i < len(raw):
        token = raw[i]
        # "&" is dropped from FE slugs rather than spelled out, so an "and"
        # on either side must not count against a match.
        if token == "and":
            i += 1
            continue
        # FE slugs split possessives ("Warhol's" -> warhol, s) while the list
        # strips the apostrophe ("Warhols"). Rejoin so both sides agree.
        if token == "s" and tokens:
            tokens[-1] += "s"
            i += 1
            continue
        # Same split on Irish prefixes ("O'Rourke" -> o, rourke).
        if token == "o" and i + 1 < len(raw):
            tokens.append(token + raw[i + 1])
            i += 2
            continue
        tokens.append(token)
        i += 1
    return tokens


def url_slug_tokens(url: str) -> list[str]:
    """Tokens of the artist-title-format slug segment of a product URL."""
    segments = [s for s in urlparse(url).path.split("/") if s]
    if len(segments) < 2:
        return []
    tokens = slug_tokens(segments[1])
    while tokens and tokens[-1] in _SLUG_FORMAT_TAIL:
        tokens.pop()
    return tokens


def build_index(urls: list[str]) -> dict[str, list[str]]:
    """Map each slug token to the URLs containing it."""
    index: dict[str, list[str]] = {}
    for url in urls:
        for token in set(url_slug_tokens(url)):
            index.setdefault(token, []).append(url)
    return index


def entry_tokens(artist: str, title: str) -> list[str]:
    return slug_tokens(artist) + slug_tokens(strip_format_suffixes(title))


def resolve(
    artist: str, title: str, index: dict[str, list[str]], *, min_tokens: int = 2
) -> str | None:
    """Best catalog URL for an entry, or None when nothing matches strictly."""
    wanted = entry_tokens(artist, title)
    if len(wanted) < min_tokens:
        return None
    wanted_set = set(wanted)

    # Start from the rarest token so the candidate pool stays small.
    rarest = min(wanted_set, key=lambda t: len(index.get(t, ())), default=None)
    if rarest is None or rarest not in index:
        return None

    best: str | None = None
    best_surplus = None
    for url in index[rarest]:
        tokens = url_slug_tokens(url)
        token_set = set(tokens)
        if not wanted_set <= token_set:
            continue
        surplus = len(token_set - wanted_set)
        if best_surplus is None or surplus < best_surplus:
            best, best_surplus = url, surplus
    return best
