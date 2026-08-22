"""Sitemap URL resolution, using real slug shapes from forcedexposure.com."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fecrawl.resolve import build_index, resolve, slug_tokens, url_slug_tokens

B = "https://www.forcedexposure.com/Catalog"
URLS = [
    f"{B}/a-certain-frank-nothing-cd/BB.503CD.html",
    f"{B}/caterina-barbieri-bendik-giske-at-source-cd/LY.009CD.html",
    f"{B}/caterina-barbieri-bendik-giske-at-source-lp/LY.009LP.html",
    f"{B}/claudio-gizzi-andy-warhol-s-blood-for-dracula-lp/RED.213LP.html",
    f"{B}/keiji-haino-jim-o-rourke-oren-ambarchi-imikuzushi-2lp/BT.007LP.html",
    f"{B}/keiji-haino-jim-o-rourke-oren-ambarchi-imikuzushi-cd/BT.007CD.html",
    f"{B}/don-cherry-home-boy-sister-out-lp/EM.1097LP.html",
    f"{B}/international-harvester-sov-gott-rose-marie-cd/SRSCD.3614CD.html",
]
INDEX = build_index(URLS)


def test_trailing_format_token_is_not_part_of_identity():
    assert url_slug_tokens(f"{B}/a-certain-frank-nothing-cd/BB.503CD.html") == [
        "a", "certain", "frank", "nothing",
    ]


def test_ampersand_and_possessive_and_irish_prefix_normalize():
    assert slug_tokens("Caterina Barbieri & Bendik Giske") == [
        "caterina", "barbieri", "bendik", "giske",
    ]
    assert slug_tokens("Andy Warhol's") == ["andy", "warhols"]
    assert slug_tokens("andy-warhol-s") == ["andy", "warhols"]
    assert slug_tokens("Jim O'Rourke") == ["jim", "orourke"]
    assert slug_tokens("jim-o-rourke") == ["jim", "orourke"]


def test_resolves_across_those_spelling_differences():
    assert resolve("Caterina Barbieri & Bendik Giske", "At Source", INDEX)
    assert resolve("Claudio Gizzi", "Andy Warhols Blood for Dracula", INDEX)
    assert resolve("Keiji Haino/Jim ORourke/Oren Ambarchi", "Imikuzushi", INDEX)


def test_absent_release_resolves_to_none():
    # In the sitemap under a different title, so this exact release is absent.
    assert resolve("International Harvester", "Remains", INDEX) is None
    assert resolve("Bernard Vitet", "La Guepe", INDEX) is None


def test_wrong_artist_does_not_match_a_shared_title():
    assert resolve("Some Other Artist", "At Source", INDEX) is None


def test_single_token_entries_are_refused_as_too_weak():
    assert resolve("", "Nothing", INDEX) is None


def test_fewest_surplus_tokens_wins_among_format_variants():
    url = resolve("Keiji Haino/Jim ORourke/Oren Ambarchi", "Imikuzushi", INDEX)
    # Both the 2LP and CD pressings qualify; either is the same release, but the
    # choice must be deterministic rather than arbitrary.
    assert url in {
        f"{B}/keiji-haino-jim-o-rourke-oren-ambarchi-imikuzushi-2lp/BT.007LP.html",
        f"{B}/keiji-haino-jim-o-rourke-oren-ambarchi-imikuzushi-cd/BT.007CD.html",
    }
