"""Fold artist/title strings into stable dedupe keys.

Forced Exposure lists the same release once per pressing, so the raw catalog
carries near-duplicates that differ only by an edition or format parenthetical:

    Alunah/Samavayo - Embers of Belief
    Alunah/Samavayo - Embers of Belief (Orange Transparent Vinyl)

Both fold to the same key. A parenthetical is only dropped when *every*
significant token inside it is format/edition vocabulary, so genuine subtitles
like "Zamia Lehmanni (Songs Of Byzantine Flowers)" survive untouched.
"""

from __future__ import annotations

import re
import unicodedata

# Tokens that mark a parenthetical as pressing metadata rather than part of the
# title. Kept deliberately narrow: a single non-vocabulary word protects the
# whole group.
_FORMAT_TOKENS = frozenset(
    """
    lp lps ep eps cd cds cdr dvd bluray vinyl wax cassette tape mc k7 flexi
    picture shaped etched dinked
    single double triple quadruple twin
    box set boxset digipak digipack gatefold sleeve jacket obi insert booklet
    remaster remastered remaster remix remixed redux rework reworked reissue
    reissued repress represses restored expanded extended complete compleat
    deluxe collector collectors anniversary edition editions version ed
    limited ltd numbered handnumbered exclusive indie import promo promotional
    advance sampler test pressing white label
    colour color colours colors coloured colored transparent translucent opaque
    clear smoke smokey marble marbled splatter splattered swirl swirled haze
    hazy galaxy cloudy milky metallic neon glow
    black white red blue green orange yellow purple violet pink gold golden
    silver grey gray brown bone cream amber magenta turquoise teal olive
    mono stereo quad ambisonic
    bonus track tracks disc discs disk
    gram grams gsm heavyweight heavy
    digital download stream streaming
    ost soundtrack score
    new sealed used
    """.split()
)

# Strong markers: a parenthetical containing one of these is pressing metadata
# even when the rest of it is noise ("(2LP, 180g)").
_STRONG_FORMAT_TOKENS = frozenset(
    """
    lp ep cd cdr dvd bluray vinyl cassette tape boxset digipak digipack
    remaster remastered reissue reissued repress redux edition gatefold
    """.split()
)

_UNIT_RE = re.compile(r"^\d+(?:g|gram|grams|gsm|cm|mm|in|inch|rpm|x)?$")
_SIZE_RE = re.compile(r'^\d+["″”]$')  # 7", 10", 12"

# Count-prefixed formats: 2LP, 3CD, 7x12". The count is not what makes these
# pressing metadata, the unit is, so they carry the same weight as a bare "lp".
_COUNTED_FORMAT_RE = re.compile(
    r"^\d+\s*x?\s*(lp|lps|ep|eps|cd|cds|cdr|dvd|mc|k7|tape|tapes|cassette|cassettes|disc|discs)$"
)

# Matches a trailing bracketed group, tolerating the unclosed ones the earlier
# extraction pass left behind ("... (Redux" with no closing paren).
_TRAILING_GROUP_RE = re.compile(r"\s*[\(\[\{]([^\(\)\[\]\{\}]*)[\)\]\}]?\s*$")

_ARTIST_NOISE_RE = re.compile(
    r"\s*\b(?:feat|feats|featuring|ft|with|vs|versus|presents|present|pres)\b\.?\s+",
    re.IGNORECASE,
)

_VARIOUS_ARTISTS = frozenset(
    {"va", "v a", "various", "various artists", "various artist", "compilation"}
)


def _strip_accents(text: str) -> str:
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def _significant_tokens(text: str) -> list[str]:
    return [t for t in re.split(r"[^0-9a-z\"″”]+", text.lower()) if t]


def _is_format_group(inner: str) -> bool:
    """True when a bracketed group is pressing metadata, not part of the title."""
    tokens = _significant_tokens(_strip_accents(inner))
    if not tokens:
        return False
    has_strong = False
    unmatched = []
    for token in tokens:
        if token in _STRONG_FORMAT_TOKENS or _COUNTED_FORMAT_RE.match(token):
            has_strong = True
            continue
        if token in _FORMAT_TOKENS or _UNIT_RE.match(token) or _SIZE_RE.match(token):
            continue
        unmatched.append(token)
    if not unmatched:
        return True
    # One stray word is tolerated when a strong marker is present, which covers
    # "(2LP, remastered 2019)" without swallowing real subtitles.
    return len(unmatched) == 1 and has_strong


def strip_format_suffixes(title: str) -> str:
    """Drop trailing pressing/edition parentheticals, however many there are."""
    current = title.strip()
    while True:
        match = _TRAILING_GROUP_RE.search(current)
        if not match or not _is_format_group(match.group(1)):
            return current
        stripped = current[: match.start()].strip()
        if not stripped:
            return current  # the parenthetical was the whole title; keep it
        current = stripped


def fold(text: str) -> str:
    """Reduce a string to its comparison form."""
    folded = _strip_accents(text).lower()
    folded = folded.replace("&", " and ")
    folded = re.sub(r"[‘’‛ʼ']", "", folded)
    folded = re.sub(r"[^0-9a-z]+", " ", folded)
    folded = re.sub(r"^\s*the\s+", "", folded)
    return re.sub(r"\s+", " ", folded).strip()


def normalize_artist(artist: str) -> str:
    """Fold an artist credit, collapsing all 'various artists' spellings."""
    primary = _ARTIST_NOISE_RE.split(artist, maxsplit=1)[0]
    folded = fold(primary or artist)
    if folded in _VARIOUS_ARTISTS:
        return "various artists"
    return folded


def normalize_title(title: str) -> str:
    return fold(strip_format_suffixes(title))


def dedupe_key(artist: str, title: str) -> tuple[str, str]:
    """The identity two catalog entries are considered duplicates on."""
    return (normalize_artist(artist), normalize_title(title))
