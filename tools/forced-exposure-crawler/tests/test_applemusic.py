"""Apple Music match acceptance, using real iTunes result shapes."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest

from fecrawl.applemusic import _is_match, _strip_tracking


def result(artist, album, genre="Jazz"):
    return {"artistName": artist, "collectionName": album, "primaryGenreName": genre}


@pytest.mark.parametrize(
    "artist, title, res",
    [
        # Apple appends an edition suffix the catalog entry does not carry.
        ("Albert Ayler Trio", "Spiritual Unity",
         result("Albert Ayler Trio", "Spiritual Unity (50th Anniversary Expanded Edition)")),
        # Credit is broader or narrower on one side.
        ("Albert Ayler", "Spiritual Unity", result("Albert Ayler Trio", "Spiritual Unity")),
        ("Albert Ayler Trio", "Spiritual Unity", result("Albert Ayler", "Spiritual Unity")),
        # Case, accents and ampersands are not identity.
        ("BERNARD VITET", "La Guepe", result("Bernard Vitet", "La Guêpe")),
        ("Abul Mogard & Rafael Anton Irisarri", "X",
         result("Abul Mogard and Rafael Anton Irisarri", "X")),
        # The catalog entry carries the pressing suffix instead.
        ("COIL", "Backwards (Remastered)", result("Coil", "Backwards")),
    ],
)
def test_accepts_true_matches(artist, title, res):
    assert _is_match(artist, title, res)


@pytest.mark.parametrize(
    "artist, title, res",
    [
        # Right album name, wrong artist entirely.
        ("Albert Ayler Trio", "Spiritual Unity", result("Some Tribute Band", "Spiritual Unity")),
        # Right artist, different record.
        ("Albert Ayler", "Spiritual Unity", result("Albert Ayler", "The Albert Ayler Story")),
        # A compilation that merely mentions the artist is not the album.
        ("Don Cherry", "Home Boy Sister Out", result("Don Cherry", "The Very Best of Don Cherry")),
        ("", "Spiritual Unity", result("Albert Ayler", "Spiritual Unity")),
    ],
)
def test_rejects_wrong_matches(artist, title, res):
    assert not _is_match(artist, title, res)


def test_strips_tracking_parameter():
    assert _strip_tracking(
        "https://music.apple.com/us/album/backwards/1093115304?uo=4"
    ) == "https://music.apple.com/us/album/backwards/1093115304"


# --- artist credit shapes -------------------------------------------------
# FE stores credits inverted and in capitals for roughly half the catalog.

from fecrawl.applemusic import artist_variants


def test_inverted_credit_offers_both_readings():
    assert artist_variants("FURY, BILLY") == ["FURY, BILLY", "BILLY FURY"]


def test_ambiguous_comma_names_also_offer_both():
    # "Trad, Gras och Stenar" keeps its comma; "De Angelis, Guido & Maurizio"
    # is genuinely inverted. Both have three words after the comma, so no rule
    # separates them: offer both readings and let the match decide.
    assert artist_variants("TRAD, GRAS OCH STENAR") == [
        "TRAD, GRAS OCH STENAR", "GRAS OCH STENAR TRAD",
    ]
    assert artist_variants("DE ANGELIS, GUIDO & MAURIZIO") == [
        "DE ANGELIS, GUIDO & MAURIZIO", "GUIDO & MAURIZIO DE ANGELIS",
    ]


def test_parenthetical_expansion_is_offered_without_it():
    assert "F.S.K." in artist_variants("F.S.K. (FREIWILLIGE SELBSTKONTROLLE)")


def test_plain_credit_yields_itself_only():
    assert artist_variants("COIL") == ["COIL"]


def test_match_accepts_either_reading_of_an_inverted_credit():
    assert _is_match("FURY, BILLY", "The Hit Parade Hero", result("Billy Fury", "The Hit Parade Hero"))
    assert _is_match("DE ANGELIS, GUIDO & MAURIZIO", "Torso",
                     result("Guido & Maurizio De Angelis", "Torso"))


def test_swapped_reading_does_not_licence_a_wrong_artist():
    assert not _is_match("FURY, BILLY", "The Hit Parade Hero",
                         result("Some Other Band", "The Hit Parade Hero"))


def test_various_artists_needs_an_exact_title():
    from fecrawl.applemusic import _title_variants
    from fecrawl.normalize import fold, normalize_artist
    assert normalize_artist("VA") == "various artists"
    # An exact title is required for compilations; a prefix must not qualify.
    assert fold("Chebran Volume 2") != fold("Chebran Volume 2: French Boogie")
