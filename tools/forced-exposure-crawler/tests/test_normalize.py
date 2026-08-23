"""Dedupe behaviour, checked against strings taken from the live Craft list."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest

from fecrawl.normalize import dedupe_key, normalize_artist, strip_format_suffixes


@pytest.mark.parametrize(
    "title, expected",
    [
        # Unclosed parentheticals, exactly as the earlier pass left them.
        ("Embers of Belief (Orange Transparent Vinyl", "Embers of Belief"),
        ("Love Is Overtaking Me (Redux", "Love Is Overtaking Me"),
        # A descriptive subtitle is not format vocabulary, so it stays: merging on
        # it would risk collapsing two genuinely different releases.
        ("Zelda Suites (The Live Album", "Zelda Suites (The Live Album"),
        # Closed pressing metadata.
        ("Aldebaran (Expanded)", "Aldebaran"),
        ("Nostromo (2LP, 180g)", "Nostromo"),
        ("Themes [Remastered]", "Themes"),
        ("Dinorwic (Clear Vinyl) (Limited Edition)", "Dinorwic"),
        # Real subtitles must survive.
        ("Zamia Lehmanni (Songs Of Byzantine Flowers)", "Zamia Lehmanni (Songs Of Byzantine Flowers)"),
        ("French Story (Movie Themes From France", "French Story (Movie Themes From France"),
        ("Silencers (The Conspiracy Theory Dossiers)", "Silencers (The Conspiracy Theory Dossiers)"),
        # A title that is nothing but a parenthetical is left alone.
        ("(Ω)", "(Ω)"),
        # Untouched titles pass through.
        ("New York Electronic, 1965", "New York Electronic, 1965"),
    ],
)
def test_strip_format_suffixes(title, expected):
    assert strip_format_suffixes(title) == expected


@pytest.mark.parametrize(
    "left, right",
    [
        # The duplicate pair sitting in the current list.
        (
            ("Alunah/Samavayo", "Embers of Belief"),
            ("Alunah/Samavayo", "Embers of Belief (Orange Transparent Vinyl"),
        ),
        # Accents, case and curly apostrophes are not identity.
        (("Bernard Vitet", "La Guêpe"), ("BERNARD VITET", "La Guepe")),
        (("Z'EV", "Sum Things"), ("Z’EV", "sum things")),
        # Ampersand vs "and".
        (("Abul Mogard & Rafael Anton Irisarri", "X"), ("Abul Mogard and Rafael Anton Irisarri", "X")),
        # Leading article.
        (("The Telescopes", "Stone Tape"), ("Telescopes", "Stone Tape")),
        # Featured-artist noise is not part of the identity.
        (("Merzbow feat. Balázs Pándi", "Live At FAC251"), ("Merzbow", "Live At FAC251")),
        # Compilation spellings collapse.
        (("VA", "Noise Forest"), ("Various Artists", "Noise Forest")),
    ],
)
def test_duplicates_collapse(left, right):
    assert dedupe_key(*left) == dedupe_key(*right)


@pytest.mark.parametrize(
    "left, right",
    [
        # Distinct releases that share a prefix must stay distinct.
        (("Don Cherry", "Live at Café Montmartre 1966 Volume Three"),
         ("Don Cherry", "Live at Cafe Monmartre 1966 Volume Two")),
        (("Alex Chilton", "Jesus Christ"), ("Alex Chilton", "Take Me Home And Make Me Like It")),
        (("MZ.412", "Hekatomb"), ("MZ.412", "Svartmyrkr")),
        # Same title, different artist.
        (("Merzbow", "Split"), ("Nadja", "Split")),
    ],
)
def test_distinct_releases_stay_distinct(left, right):
    assert dedupe_key(*left) != dedupe_key(*right)


def test_various_artists_normalizes():
    assert normalize_artist("V/A") == "various artists"
    assert normalize_artist("Various") == "various artists"


def test_joined_credits_match_across_connectors():
    # A shop writes a split with a slash; a streaming service uses "&".
    assert dedupe_key("Alunah/Samavayo", "Embers of Belief") == dedupe_key(
        "Alunah & Samavayo", "Embers of Belief"
    )
    assert normalize_artist("Keiji Haino/Jim O'Rourke") == normalize_artist(
        "Keiji Haino & Jim O'Rourke"
    )


def test_dropping_the_connector_does_not_merge_different_artists():
    assert normalize_artist("Alunah") != normalize_artist("Alunah & Samavayo")


def test_various_artists_still_collapses():
    assert normalize_artist("V/A") == "various artists"
