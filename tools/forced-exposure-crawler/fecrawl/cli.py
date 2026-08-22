"""Command line entry point: probe, discover, crawl, merge."""

from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path

from . import probe as probe_mod
from .craft import merge, parse_existing, render
from .fetch import FetchError, Fetcher
from .parse import find_next_page, find_product_links, load_config, parse_product
from .records import Release, read_jsonl, write_jsonl

log = logging.getLogger("fecrawl")

DEFAULT_CONFIG = Path(__file__).resolve().parent.parent / "selectors.toml"
DEFAULT_CACHE = Path(".cache")


def _fetcher(args: argparse.Namespace) -> Fetcher:
    return Fetcher(
        Path(args.cache),
        delay=args.delay,
        offline=getattr(args, "offline", False),
        respect_robots=not getattr(args, "ignore_robots", False),
    )


def cmd_probe(args: argparse.Namespace) -> int:
    fetcher = _fetcher(args)
    html = fetcher.get(args.url, refresh=args.refresh)
    report = probe_mod.probe(html, args.url)
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(probe_mod.format_report(report))
    return 0


def cmd_discover(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    fetcher = _fetcher(args)
    seeds = args.seed or config["listing"].get("seeds", [])
    if not seeds:
        log.error("no seed URLs: pass --seed or set listing.seeds in %s", args.config)
        return 2

    seen: dict[str, None] = {}
    for seed in seeds:
        page_url, pages = seed, 0
        while page_url and pages < args.max_pages:
            try:
                html = fetcher.get(page_url, refresh=args.refresh)
            except FetchError as exc:
                log.error("%s", exc)
                break
            links = find_product_links(html, page_url, config)
            for link in links:
                seen.setdefault(link, None)
            log.info("%s -> %d links (%d total)", page_url, len(links), len(seen))
            pages += 1
            page_url = find_next_page(html, page_url, config)

    Path(args.out).write_text("\n".join(seen) + "\n", encoding="utf-8")
    log.info("wrote %d product URLs to %s", len(seen), args.out)
    return 0


def cmd_crawl(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    fetcher = _fetcher(args)
    urls = [u.strip() for u in Path(args.urls).read_text(encoding="utf-8").splitlines() if u.strip()]

    releases: list[Release] = []
    skipped = 0
    for index, url in enumerate(urls, 1):
        try:
            html = fetcher.get(url, refresh=args.refresh)
        except FetchError as exc:
            log.warning("%s", exc)
            continue
        release = parse_product(html, url, config)
        if release is None:
            skipped += 1
            log.warning("no artist/title extracted: %s", url)
            continue
        releases.append(release)
        if index % 50 == 0:
            log.info("%d/%d pages", index, len(urls))

    write_jsonl(args.out, releases)
    no_genre = sum(1 for r in releases if not r.genre)
    log.info(
        "%d releases -> %s (%d unparsed, %d without genre, %d fetched, %d cached)",
        len(releases), args.out, skipped, no_genre,
        fetcher.stats.fetched, fetcher.stats.from_cache,
    )
    return 0


def cmd_merge(args: argparse.Namespace) -> int:
    existing = parse_existing(Path(args.existing).read_text(encoding="utf-8")) if args.existing else []
    crawled = list(read_jsonl(args.releases)) if args.releases else []
    result = merge(existing, crawled)

    Path(args.out).write_text(render(result.entries, genre_line=not args.no_genre_line) + "\n", encoding="utf-8")
    print(
        f"existing={len(existing)} crawled={len(crawled)} "
        f"added={result.added} collapsed={result.duplicates_collapsed} "
        f"genres_filled={result.genres_filled} "
        f"total={len(result.entries)} missing_genre={result.missing_genre}",
        file=sys.stderr,
    )
    log.info("wrote %s", args.out)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="fecrawl", description=__doc__)
    parser.add_argument("--cache", default=str(DEFAULT_CACHE), help="HTML cache directory")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG), help="selectors.toml path")
    parser.add_argument("--delay", type=float, default=1.5, help="seconds between requests")
    parser.add_argument("--refresh", action="store_true", help="bypass the cache")
    parser.add_argument("--offline", action="store_true", help="cache only, never fetch")
    parser.add_argument("--ignore-robots", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("-v", "--verbose", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("probe", help="dump one page's structure")
    p.add_argument("url")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_probe)

    p = sub.add_parser("discover", help="collect product URLs from listing pages")
    p.add_argument("--seed", action="append")
    p.add_argument("--max-pages", type=int, default=200)
    p.add_argument("--out", default="urls.txt")
    p.set_defaults(func=cmd_discover)

    p = sub.add_parser("crawl", help="extract releases from product pages")
    p.add_argument("--urls", default="urls.txt")
    p.add_argument("--out", default="releases.jsonl")
    p.set_defaults(func=cmd_crawl)

    p = sub.add_parser("merge", help="merge into the existing list, dedupe, render")
    p.add_argument("--existing", help="markdown export of the current Craft list")
    p.add_argument("--releases", default="releases.jsonl")
    p.add_argument("--out", default="merged.md")
    p.add_argument("--no-genre-line", action="store_true")
    p.set_defaults(func=cmd_merge)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(message)s",
    )
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
