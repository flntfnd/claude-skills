"""Representative-track selection."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fecrawl.tracks import candidate_titles, select_tracks

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


def names(tracks):
    return [t["trackName"] for t in tracks]


def test_every_validated_mention_is_kept():
    tracks, source = select_tracks(["Amber Rain", "Backwards"], TRACKLIST)
    assert names(tracks) == ["Backwards", "Amber Rain"]  # album order
    assert source == "review"


def test_all_mentions_kept_however_many():
    picked = ["Intro", "Backwards", "Amber Rain", "Fire of the Green Dragon"]
    tracks, source = select_tracks(picked, TRACKLIST)
    assert len(tracks) == 4
    assert source == "review"


def test_same_track_named_twice_counts_once():
    tracks, _ = select_tracks(["Amber Rain", "amber rain", "AMBER RAIN"], TRACKLIST)
    assert names(tracks) == ["Amber Rain"]


def test_single_mention_yields_single_track():
    tracks, source = select_tracks(["Amber Rain"], TRACKLIST)
    assert names(tracks) == ["Amber Rain"] and source == "review"


def test_unvalidated_candidates_fall_back_to_opening_only():
    # Quoted prose that is not a track on this album must not be taken as one.
    tracks, source = select_tracks(["US", "dehumanized"], TRACKLIST)
    assert names(tracks) == ["Intro"]
    assert source == "opening"


def test_no_mention_falls_back_to_opening_only():
    tracks, source = select_tracks([], TRACKLIST)
    assert names(tracks) == ["Intro"] and source == "opening"


def test_mix_of_real_and_noise_keeps_only_the_real():
    tracks, source = select_tracks(["US", "Amber Rain", "dehumanized"], TRACKLIST)
    assert names(tracks) == ["Amber Rain"] and source == "review"


def test_ordering_is_by_disc_then_track():
    tracks, _ = select_tracks(["Fire of the Green Dragon", "Backwards"], TRACKLIST)
    assert names(tracks) == ["Backwards", "Fire of the Green Dragon"]


def test_empty_tracklist_is_handled():
    assert select_tracks(["Amber Rain"], []) == ([], "none")


def test_case_and_punctuation_insensitive_match():
    tracks, source = select_tracks(["amber rain"], TRACKLIST)
    assert names(tracks) == ["Amber Rain"] and source == "review"
