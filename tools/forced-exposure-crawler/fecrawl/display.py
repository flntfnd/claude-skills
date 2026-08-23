"""Turn FE's storage form of an artist credit into something readable.

FE stores credits in capitals and, for about half the catalog, in inverted
library order ("FURY, BILLY"). Apple Music's spelling is preferred when a
release resolved there, since it is authoritative. This is the fallback.
"""

from __future__ import annotations

import re

# Words that stay lowercase inside a title-cased name.
_MINOR = frozenset("a an and de du der des di el en et la le les of och or the van von y".split())

# Tokens that should stay exactly as FE wrote them.
_KEEP_UPPER = re.compile(r"^(?:[A-Z]\.){2,}$|^[IVXLC]+$|^\d+$")


# Credits that are acronyms rather than names.
_ACRONYMS = {"VA": "VA", "V/A": "VA"}

# A one-letter prefix joined by an apostrophe keeps its capital: O'Rourke,
# D'Angelo. A possessive ("Warhol's") must not be touched.
_NAME_PREFIX = re.compile(r"\b([A-Za-z])'([a-z])")


def _cap_word(word: str) -> str:
    if not word or _KEEP_UPPER.match(word):
        return word
    return word[:1].upper() + word[1:].lower()


def _title_case(text: str) -> str:
    # Names run together with slashes and parentheses, each of which starts a
    # new name that needs its own capital.
    parts = re.split(r"([/()\[\]])", text)
    out: list[str] = []
    for part in parts:
        if part in "/()[]":
            out.append(part)
            continue
        # Preserve surrounding spacing; splitting on the delimiters above
        # would otherwise close up "F.S.K. (" into "F.S.K.(".
        lead = part[: len(part) - len(part.lstrip())]
        trail = part[len(part.rstrip()) :]
        words = part.split()
        cased = [
            w.lower() if index and w.lower() in _MINOR else _cap_word(w)
            for index, w in enumerate(words)
        ]
        out.append(lead + " ".join(cased) + trail)
    joined = "".join(out)
    return _NAME_PREFIX.sub(lambda m: f"{m.group(1).upper()}'{m.group(2).upper()}", joined)


def display_artist(artist: str) -> str:
    """Readable form of an FE artist credit.

    Only a clear personal-name inversion is swapped: a single comma with one or
    two words after it. Longer tails are left alone because a comma there is as
    likely to belong to the name ("Trad, Gras och Stenar") as to mark an
    inversion, and guessing wrong renames the artist.
    """
    artist = artist.strip()
    if artist.upper() in _ACRONYMS:
        return _ACRONYMS[artist.upper()]
    head, sep, tail = artist.partition(",")
    if sep and head.strip() and 1 <= len(tail.split()) <= 2 and "," not in tail:
        artist = f"{tail.strip()} {head.strip()}"
    return _title_case(artist)
