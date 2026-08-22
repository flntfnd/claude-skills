"""Config-driven extraction.

Nothing about Forced Exposure's markup is hardcoded here. Field rules live in
`selectors.toml` and are tried in order until one yields a value, so adapting to
the real page structure is a config edit rather than a code change.

Rule types:
  css    - CSS selector; takes element text, or an attribute via `attr`
  label  - finds a label like "Genre:" and takes the value beside or after it,
           which is how table-and-label layouts of this vintage are built
  meta   - <meta name=... / property=...> content
  jsonld - dotted path into any application/ld+json block on the page
  regex  - pattern over the page's flattened text; group 1 (or `group`) wins
"""

from __future__ import annotations

import json
import re
import tomllib
from pathlib import Path
from typing import Any, Iterable

from bs4 import BeautifulSoup, Tag

from .records import Release

_WS_RE = re.compile(r"\s+")


class SelectorConfigError(ValueError):
    """selectors.toml is missing something the extractor needs."""


def _clean(text: str | None) -> str:
    return _WS_RE.sub(" ", text or "").strip(" \t\r\n:-–—")


def load_config(path: str | Path) -> dict[str, Any]:
    with open(path, "rb") as handle:
        config = tomllib.load(handle)
    for section in ("site", "listing", "product"):
        if section not in config:
            raise SelectorConfigError(f"selectors.toml is missing [{section}]")
    return config


def _apply_css(soup: BeautifulSoup, rule: dict[str, Any]) -> str:
    for element in soup.select(rule["selector"]):
        attr = rule.get("attr")
        value = _clean(element.get(attr) if attr else element.get_text(" "))
        if value:
            return value
    return ""


def _apply_label(soup: BeautifulSoup, rule: dict[str, Any]) -> str:
    """Find a label node, then take the value that follows it.

    Handles both `<td>Genre:</td><td>Ambient</td>` and a run-on
    `Genre: Ambient` inside a single element.
    """
    pattern = re.compile(rule["label"], re.IGNORECASE)
    scope = rule.get("scope", "td, th, dt, span, strong, b, p, li, div")
    for element in soup.select(scope):
        text = _clean(element.get_text(" "))
        if not text or not pattern.match(text):
            continue
        remainder = _clean(pattern.sub("", text, count=1))
        if remainder:
            return remainder
        sibling = element.find_next_sibling()
        if isinstance(sibling, Tag):
            value = _clean(sibling.get_text(" "))
            if value:
                return value
    return ""


def _apply_meta(soup: BeautifulSoup, rule: dict[str, Any]) -> str:
    key = rule["name"]
    for attr in ("property", "name", "itemprop"):
        node = soup.find("meta", attrs={attr: key})
        if isinstance(node, Tag):
            value = _clean(node.get("content"))
            if value:
                return value
    return ""


def _walk_jsonld(soup: BeautifulSoup) -> Iterable[Any]:
    for script in soup.find_all("script", attrs={"type": "application/ld+json"}):
        try:
            payload = json.loads(script.string or "")
        except (json.JSONDecodeError, TypeError):
            continue
        stack = [payload]
        while stack:
            node = stack.pop()
            if isinstance(node, dict):
                yield node
                stack.extend(node.values())
            elif isinstance(node, list):
                stack.extend(node)


def _apply_jsonld(soup: BeautifulSoup, rule: dict[str, Any]) -> str:
    path = rule["path"].split(".")
    for node in _walk_jsonld(soup):
        cursor: Any = node
        for key in path:
            if not isinstance(cursor, dict) or key not in cursor:
                cursor = None
                break
            cursor = cursor[key]
        if isinstance(cursor, str) and _clean(cursor):
            return _clean(cursor)
    return ""


def _apply_regex(soup: BeautifulSoup, rule: dict[str, Any]) -> str:
    match = re.search(rule["pattern"], soup.get_text(" "), re.IGNORECASE | re.DOTALL)
    return _clean(match.group(rule.get("group", 1))) if match else ""


_RULE_TYPES = {
    "css": _apply_css,
    "label": _apply_label,
    "meta": _apply_meta,
    "jsonld": _apply_jsonld,
    "regex": _apply_regex,
}


def extract_field(soup: BeautifulSoup, rules: list[dict[str, Any]]) -> str:
    for rule in rules:
        kind = rule.get("type")
        handler = _RULE_TYPES.get(kind)
        if handler is None:
            raise SelectorConfigError(f"unknown rule type: {kind!r}")
        value = handler(soup, rule)
        if value:
            return value
    return ""


def _split_list(value: str, separators: str) -> list[str]:
    if not value:
        return []
    parts = re.split(f"[{re.escape(separators)}]", value)
    return [p for p in (_clean(part) for part in parts) if p]


def parse_product(html: str, url: str, config: dict[str, Any]) -> Release | None:
    """Build a Release from a product page, or None if it has no artist/title."""
    soup = BeautifulSoup(html, "lxml")
    product = config["product"]
    separators = config.get("site", {}).get("list_separators", ",/;")

    artist = extract_field(soup, product.get("artist", []))
    title = extract_field(soup, product.get("title", []))

    # Some layouts carry only a combined "Artist - Title" heading.
    if (not artist or not title) and product.get("combined"):
        combined = extract_field(soup, product["combined"])
        pattern = config["site"].get("combined_split", r"\s+[-–—]\s+")
        pieces = re.split(pattern, combined, maxsplit=1)
        if len(pieces) == 2:
            artist = artist or _clean(pieces[0])
            title = title or _clean(pieces[1])

    if not artist or not title:
        return None

    return Release(
        artist=artist,
        title=title,
        genre=extract_field(soup, product.get("genre", [])),
        label=extract_field(soup, product.get("label", [])),
        catalog_no=extract_field(soup, product.get("catalog_no", [])),
        url=url,
        formats=_split_list(extract_field(soup, product.get("format", [])), separators),
    )


def find_product_links(html: str, base_url: str, config: dict[str, Any]) -> list[str]:
    """Product-page URLs linked from a listing page."""
    from urllib.parse import urljoin

    soup = BeautifulSoup(html, "lxml")
    listing = config["listing"]
    pattern = re.compile(listing["product_url_pattern"])
    found: dict[str, None] = {}
    for anchor in soup.select(listing.get("link_selector", "a[href]")):
        href = anchor.get("href")
        if not href:
            continue
        absolute = urljoin(base_url, href).split("#")[0]
        if pattern.search(absolute):
            found[absolute] = None
    return list(found)


def find_next_page(html: str, base_url: str, config: dict[str, Any]) -> str | None:
    from urllib.parse import urljoin

    selector = config["listing"].get("next_page_selector")
    if not selector:
        return None
    soup = BeautifulSoup(html, "lxml")
    node = soup.select_one(selector)
    if isinstance(node, Tag) and node.get("href"):
        return urljoin(base_url, node["href"])
    return None
