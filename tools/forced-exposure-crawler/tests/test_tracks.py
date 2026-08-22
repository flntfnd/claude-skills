"""Representative-track selection."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fecrawl.tracks import candidate_titles, choose_track

TRACKLIST = [
    {"trackName": "Intro", "trackNumber": 1, "discNumber": 1},
    {"trackName": "Backwards", "trackNumber": 2, "discNumber": 1},
    {"trackName": "Amber Rain", "trackNumber": 3, "discNumber": 1},
    {"trackName": "Fire of the Green Dragon", "trackNumber": 1, "discNumber": 2},
]


def desc(inner):
    return f'<html><body><div class="prod-desc">{inner}</div></body></html>'


def test_reads_quoted_and_italic_candidates():
    got = candidate_titles(desc('The peak is <i>Amber Rain</i>, and "Backwards" follows.'))
    assert "Amber Rain" in got and "Backwards" in got


def test_trailing_punctuation_is_stripped():
    assert "Amber Rain" in candidate_titles(desc('the centrepiece, "Amber Rain," is superb'))


def test_whole_paragraph_quotes_are_not_candidates():
    long_quote = (
        "a record that sounds like nothing else released that year or since and "
        "which continues to reward the patient listener on every fresh encounter"
    )
    assert candidate_titles(desc(f'<p>"{long_quote}"</p>')) == []


def test_genuinely_long_titles_survive():
    # This catalog really does carry titles this long.
    title = "I wonder if you noticed Im sorry Is such a lovely sound"
    assert title in candidate_titles(desc(f'<p>the opener, "{title}", is the peak</p>'))


def test_no_description_yields_no_candidates():
    assert candidate_titles("<html><body><p>no description here</p></body></html>") == []


def test_validated_mention_wins_and_is_marked_as_such():
    track, source = choose_track(["Amber Rain"], TRACKLIST)
    assert track["trackName"] == "Amber Rain"
    assert source == "review"


def test_unvalidated_candidates_fall_back_to_opening():
    # Quoted prose that is not a track on this album must not be taken as one.
    track, source = choose_track(["US", "dehumanized"], TRACKLIST)
    assert track["trackName"] == "Intro"
    assert source == "opening"


def test_no_mention_falls_back_to_opening():
    track, source = choose_track([], TRACKLIST)
    assert track["trackName"] == "Intro"
    assert source == "opening"


def test_opening_track_respects_disc_order():
    shuffled = list(reversed(TRACKLIST))
    track, _ = choose_track([], shuffled)
    assert track["trackName"] == "Intro"


def test_empty_tracklist_is_handled():
    assert choose_track(["Amber Rain"], []) == (None, "none")


def test_case_and_punctuation_insensitive_match():
    track, source = choose_track(["amber rain"], TRACKLIST)
    assert track["trackName"] == "Amber Rain" and source == "review"
