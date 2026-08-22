"""Merge and render behaviour, using lines shaped like the real Craft lists."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fecrawl.craft import merge, parse_existing, render
from fecrawl.records import Release

EXISTING = """
Compiled from Forced Exposure's curated picks.

- Alunah/Samavayo — Embers of Belief
- Alunah/Samavayo — Embers of Belief (Orange Transparent Vinyl
- [COIL — Backwards](https://coldspring.co.uk/x) (CSR203)
- Albert Ayler Trio — Spiritual Unity
"""


def test_parses_both_line_shapes():
    entries = parse_existing(EXISTING)
    assert len(entries) == 4
    linked = next(e for e in entries if e.artist == "COIL")
    assert linked.title == "Backwards"
    assert linked.url == "https://coldspring.co.uk/x"
    assert linked.catalog_no == "CSR203"
    assert entries[0].sources == ["craft"]


def test_prose_lines_are_ignored():
    assert all("Compiled from" not in e.artist for e in parse_existing(EXISTING))


def test_existing_internal_duplicates_collapse():
    result = merge(parse_existing(EXISTING), [])
    assert result.duplicates_collapsed == 1
    assert result.added == 0
    titles = [e.title for e in result.entries]
    assert len(titles) == 3


def test_crawl_fills_genre_without_adding_a_duplicate():
    existing = parse_existing(EXISTING)
    crawled = [
        Release(
            artist="ALBERT AYLER TRIO",
            title="Spiritual Unity (Reissue)",
            genre="Free Jazz",
            catalog_no="ESP1002LP",
            url="https://www.forcedexposure.com/Catalog/x",
        )
    ]
    result = merge(existing, crawled)
    assert result.added == 0
    assert result.genres_filled == 1
    ayler = next(e for e in result.entries if "Ayler" in e.artist.title())
    assert ayler.genre == "Free Jazz"
    assert ayler.catalog_no == "ESP1002LP"
    assert sorted(ayler.sources) == ["craft", "forcedexposure"]


def test_genuinely_new_release_is_added():
    result = merge(
        parse_existing(EXISTING),
        [Release(artist="Nurse With Wound", title="Soliloquy For Lilith", genre="Industrial")],
    )
    assert result.added == 1


def test_existing_entry_is_never_dropped():
    existing = parse_existing(EXISTING)
    result = merge(existing, [Release(artist="Someone Else", title="Other")])
    assert "backwards" in " ".join(e.title.lower() for e in result.entries)


def test_missing_genre_is_counted_and_rendered_as_unknown():
    result = merge(parse_existing(EXISTING), [])
    assert result.missing_genre == 3
    out = render(result.entries)
    assert out.count("  - Genre:") == 3
    assert "  - Genre: Unknown" in out


def test_render_shape():
    out = render([Release(artist="COIL", title="Backwards", genre="Industrial",
                          url="https://x/y", catalog_no="CSR203")])
    assert out == "- [COIL — Backwards](https://x/y) (CSR203)\n  - Genre: Industrial"
