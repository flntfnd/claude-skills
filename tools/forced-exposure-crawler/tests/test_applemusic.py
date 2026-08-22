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
