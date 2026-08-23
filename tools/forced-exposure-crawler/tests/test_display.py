"""Readable artist credits from FE's storage form."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest

from fecrawl.display import display_artist


@pytest.mark.parametrize(
    "stored, shown",
    [
        # Clear personal-name inversions are swapped back.
        ("FURY, BILLY", "Billy Fury"),
        ("O'SULLIVAN, DANIEL", "Daniel O'Sullivan"),
        ("HOLMES, JAKE", "Jake Holmes"),
        # Plain credits are only re-cased.
        ("COIL", "Coil"),
        ("ALVARIUS B.", "Alvarius B."),
        # Initialisms keep their capitals.
        ("F.S.K. (FREIWILLIGE SELBSTKONTROLLE)", "F.S.K. (Freiwillige Selbstkontrolle)"),
        # Each name in a collaboration gets its own capital.
        ("GRATEFUL DEAD/JOHN OSWALD", "Grateful Dead/John Oswald"),
        ("KEIJI HAINO/JIM O'ROURKE/OREN AMBARCHI", "Keiji Haino/Jim O'Rourke/Oren Ambarchi"),
        # FE's compilation code is an acronym, not a name.
        ("VA", "VA"),
    ],
)
def test_display_artist(stored, shown):
    assert display_artist(stored) == shown


@pytest.mark.parametrize(
    "stored",
    [
        # A comma with a long tail is left alone: it is as likely to belong to
        # the name as to mark an inversion, and guessing wrong renames the act.
        "TRAD, GRAS OCH STENAR",
        "AK'CHAMEL, THE GIVER OF ILLNESS",
        "DE ANGELIS, GUIDO & MAURIZIO",
    ],
)
def test_ambiguous_comma_credits_are_not_reordered(stored):
    shown = display_artist(stored)
    assert "," in shown
    # Re-cased, but the word order is untouched.
    assert [w.lower() for w in shown.split()] == [w.lower() for w in stored.split()]


def test_minor_words_stay_lowercase_inside_a_name():
    assert display_artist("TRAD, GRAS OCH STENAR") == "Trad, Gras och Stenar"


def test_leading_minor_word_keeps_its_capital():
    assert display_artist("THE TELESCOPES") == "The Telescopes"


def test_possessive_is_not_capitalised_like_a_prefix():
    # "Warhol's" must not become "Warhol'S"; only O'/D'-style prefixes do that.
    assert display_artist("ANDY WARHOL'S FACTORY") == "Andy Warhol's Factory"
