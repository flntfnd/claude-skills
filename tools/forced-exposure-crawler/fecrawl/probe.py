"""Report a page's structure so selectors can be written from evidence.

Run this against a real listing page and a real product page; the output names
the label/value pairs, headings and link shapes that the rules in
selectors.toml should target.
"""

from __future__ import annotations

import json
import re
from collections import Counter
from urllib.parse import urljoin, urlparse

from bs4 import BeautifulSoup, Tag

_LABEL_RE = re.compile(r"^\s*([A-Za-z][A-Za-z /#&.]{1,24})\s*:\s*(.{1,120})$")
_WS_RE = re.compile(r"\s+")


def _clean(text: str | None) -> str:
    return _WS_RE.sub(" ", text or "").strip()


def _describe(element: Tag) -> str:
    classes = ".".join(element.get("class", []) or [])
    ident = f"#{element.get('id')}" if element.get("id") else ""
    return f"{element.name}{ident}{'.' + classes if classes else ''}"


def probe(html: str, url: str) -> dict:
    soup = BeautifulSoup(html, "lxml")

    headings = [
        {"selector": _describe(h), "text": _clean(h.get_text(" "))[:120]}
        for h in soup.select("h1, h2, h3")[:12]
        if _clean(h.get_text(" "))
    ]

    # Label/value pairs, both run-on ("Genre: Ambient") and split across cells.
    pairs: list[dict] = []
    for element in soup.select("td, th, dt, dd, li, p, span, strong, b, div"):
        if element.find(["td", "th", "li", "p", "div"]):
            continue  # only leaf-ish nodes
        text = _clean(element.get_text(" "))
        match = _LABEL_RE.match(text)
        if match:
            pairs.append(
                {
                    "label": match.group(1).strip(),
                    "value": match.group(2).strip()[:80],
                    "selector": _describe(element),
                    "shape": "run-on",
                }
            )
            continue
        # Labels are not always punctuated: FE uses a bare <div>Genre</div>
        # followed by its value sibling.
        if len(text) < 28 and (text.endswith(":") or text.isalnum() or " " in text):
            sibling = element.find_next_sibling()
            if isinstance(sibling, Tag):
                value = _clean(sibling.get_text(" "))
                if value:
                    pairs.append(
                        {
                            "label": text.rstrip(":").strip(),
                            "value": value[:80],
                            "selector": _describe(element),
                            "shape": "sibling",
                        }
                    )

    # Link shapes, grouped by path prefix, to find the product-URL pattern.
    host = urlparse(url).netloc
    prefixes: Counter[str] = Counter()
    samples: dict[str, str] = {}
    for anchor in soup.select("a[href]"):
        absolute = urljoin(url, anchor["href"])
        parts = urlparse(absolute)
        if parts.netloc != host:
            continue
        segments = [s for s in parts.path.split("/") if s]
        # Group at both depths: depth 1 shows which section holds the catalog,
        # depth 2 shows whether product URLs sit one level below it.
        for depth in (1, 2):
            if len(segments) < depth:
                continue
            prefix = "/" + "/".join(segments[:depth])
            prefixes[prefix] += 1
            samples.setdefault(prefix, absolute)

    jsonld = []
    for script in soup.find_all("script", attrs={"type": "application/ld+json"}):
        try:
            jsonld.append(json.loads(script.string or ""))
        except (json.JSONDecodeError, TypeError):
            jsonld.append({"_unparseable": True})

    metas = {
        m.get("property") or m.get("name"): _clean(m.get("content"))
        for m in soup.find_all("meta")
        if (m.get("property") or m.get("name")) and m.get("content")
    }

    return {
        "url": url,
        "title": _clean(soup.title.string if soup.title else ""),
        "headings": headings,
        "label_pairs": pairs[:40],
        "link_prefixes": [
            {"prefix": p, "count": c, "sample": samples[p]}
            for p, c in prefixes.most_common(15)
        ],
        "jsonld": jsonld[:3],
        "meta": {k: v for k, v in list(metas.items())[:15]},
        "tables": len(soup.find_all("table")),
        "frames": len(soup.find_all(["frame", "iframe"])),
    }


def format_report(report: dict) -> str:
    out = [f"URL:    {report['url']}", f"TITLE:  {report['title']}",
           f"tables={report['tables']} frames={report['frames']} "
           f"jsonld={len(report['jsonld'])}", ""]
    out.append("HEADINGS")
    for h in report["headings"] or [{"selector": "(none)", "text": ""}]:
        out.append(f"  {h['selector']:<32} {h['text']}")
    out.append("")
    out.append("LABEL / VALUE PAIRS  (candidates for genre, label, cat no, format)")
    for p in report["label_pairs"] or []:
        out.append(f"  {p['label']:<16} = {p['value']:<44} [{p['shape']}] {p['selector']}")
    if not report["label_pairs"]:
        out.append("  (none found)")
    out.append("")
    out.append("LINK PREFIXES  (candidates for product_url_pattern)")
    for link in report["link_prefixes"]:
        out.append(f"  {link['count']:>5}x  {link['prefix']:<28} {link['sample']}")
    if report["meta"]:
        out.append("")
        out.append("META")
        for k, v in report["meta"].items():
            out.append(f"  {k:<28} {v[:80]}")
    return "\n".join(out)
