"""Rule-engine behaviour, exercised against markup of the vintage FE uses."""

import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fecrawl.parse import find_product_links, parse_product

CONFIG = tomllib.loads("""
[site]
list_separators = ",/;"
combined_split = '\\s+[-–—]\\s+'

[listing]
link_selector = "a[href]"
product_url_pattern = "/Catalog/[^/]+"

[[product.combined]]
type = "css"
selector = "h1.title"

[[product.genre]]
type = "label"
label = "genre\\\\s*:?"

[[product.label]]
type = "label"
label = "label\\\\s*:?"

[[product.catalog_no]]
type = "label"
label = "cat(?:alog)?\\\\s*(?:no|#)?\\\\s*:?"

[[product.format]]
type = "label"
label = "format\\\\s*:?"
""")

# A table-and-label layout: the label sits in its own cell.
TABLE_PAGE = """
<html><body>
  <h1 class="title">ALBERT AYLER TRIO &mdash; Spiritual Unity</h1>
  <table>
    <tr><td>Label:</td><td>ESP-Disk</td></tr>
    <tr><td>Cat #:</td><td>ESP1002LP</td></tr>
    <tr><td>Genre:</td><td>Free Jazz</td></tr>
    <tr><td>Format:</td><td>LP, Reissue</td></tr>
  </table>
</body></html>
"""

# A run-on layout: label and value share one element.
RUNON_PAGE = """
<html><body>
  <h1 class="title">COIL - Backwards</h1>
  <p>Label: Cold Spring</p>
  <p>Genre: Industrial / Electronic</p>
</body></html>
"""


def test_parses_table_layout():
    release = parse_product(TABLE_PAGE, "https://example.test/Catalog/x", CONFIG)
    assert release.artist == "ALBERT AYLER TRIO"
    assert release.title == "Spiritual Unity"
    assert release.genre == "Free Jazz"
    assert release.label == "ESP-Disk"
    assert release.catalog_no == "ESP1002LP"
    assert release.formats == ["LP", "Reissue"]
    assert release.url == "https://example.test/Catalog/x"


def test_parses_runon_layout():
    release = parse_product(RUNON_PAGE, "https://example.test/Catalog/y", CONFIG)
    assert release.artist == "COIL"
    assert release.title == "Backwards"
    assert release.genre == "Industrial / Electronic"
    assert release.label == "Cold Spring"


def test_missing_artist_and_title_is_skipped():
    assert parse_product("<html><body><p>nothing</p></body></html>", "u", CONFIG) is None


def test_absent_field_is_empty_not_an_error():
    release = parse_product(RUNON_PAGE, "u", CONFIG)
    assert release.catalog_no == ""
    assert release.formats == []


def test_finds_and_dedupes_product_links():
    html = """
    <a href="/Catalog/aaa">a</a>
    <a href="/Catalog/aaa#tracks">a again</a>
    <a href="https://example.test/Catalog/bbb">b</a>
    <a href="/about">not a product</a>
    """
    links = find_product_links(html, "https://example.test/browse", CONFIG)
    assert links == [
        "https://example.test/Catalog/aaa",
        "https://example.test/Catalog/bbb",
    ]
