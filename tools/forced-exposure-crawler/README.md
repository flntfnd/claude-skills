# Forced Exposure crawler

Extracts the forcedexposure.com catalog into `artist / title / genre / label /
catalog no / format`, merges it into the existing **Forced Exposure — Album
List** in Craft, and renders the result with a genre line per entry.

## Status

The extraction engine, dedupe, merge and rendering are complete and tested. The
rules in `selectors.toml` marked `VERIFY` are written against the *shape* of a
catalog page of this vintage, not against captured markup: forcedexposure.com
was serving a site-wide maintenance page (HTTP 503, `server: awselb/2.0`) when
this was built, so no page could be read. Confirm them with `probe` before
trusting a full crawl.

## Install

```sh
pip install -r requirements.txt
```

## Use

Run `probe` first, against one listing page and one product page. Its output
names the label/value pairs and link shapes the `VERIFY` rules should target.

```sh
python -m fecrawl.cli probe https://www.forcedexposure.com/            # listing
python -m fecrawl.cli probe https://www.forcedexposure.com/Catalog/... # product
```

Correct `selectors.toml` from what it reports, then:

```sh
python -m fecrawl.cli discover --out urls.txt
python -m fecrawl.cli crawl --urls urls.txt --out releases.jsonl
python -m fecrawl.cli merge --existing craft-export.md \
                            --releases releases.jsonl --out merged.md
```

`merge` prints a summary to stderr:

```
existing=661 crawled=N added=N collapsed=N genres_filled=N total=N missing_genre=N
```

`merged.md` pastes straight into Craft. Entries render as
`- [ARTIST — Title](url) (CATNO)` with an indented `- Genre: ...` beneath,
matching the house format used by the sibling album lists. Entries whose genre
could not be resolved render as `Genre: Unknown` rather than being dropped or
guessed at, and `missing_genre` counts them.

## Behaviour worth knowing

**Every response is cached** under `--cache` (default `.cache/`). Crawl once,
then iterate on extraction with `--offline`, which never touches the network.
This is the intended working loop; it also means a re-run after a parser fix
costs nothing and puts no further load on the site.

**Politeness is on by default**: `robots.txt` is honoured, requests are spaced
by `--delay` (1.5s) with jitter, and retries back off exponentially on 429/5xx.

**Dedupe** folds accents, case, curly apostrophes, `&`/`and`, a leading `The`,
and featured-artist noise, and collapses every spelling of "various artists".
It also strips trailing pressing parentheticals, so these are one entry:

```
Alunah/Samavayo — Embers of Belief
Alunah/Samavayo — Embers of Belief (Orange Transparent Vinyl
```

The rule is deliberately conservative: a parenthetical is only dropped when
every significant token inside it is format vocabulary (`vinyl`, `2LP`,
`remastered`, colours, weights). A single ordinary word protects the whole
group, so real subtitles like `Zamia Lehmanni (Songs Of Byzantine Flowers)`
survive. Merging two distinct releases is the worse error, so ambiguous cases
stay separate. Unclosed parentheticals are handled — the earlier extraction
pass left a number of them in the list.

**The existing list is never truncated.** Merge only adds new releases and
fills empty fields; an entry the crawl does not rediscover (deleted catalog
page, long out of print) is carried through untouched.

## Layout

```
fecrawl/fetch.py      cached, rate-limited, robots-aware HTTP
fecrawl/probe.py      dumps page structure so selectors are written from evidence
fecrawl/parse.py      config-driven extraction (css / label / meta / jsonld / regex)
fecrawl/normalize.py  fold artist+title into dedupe keys
fecrawl/craft.py      merge into the existing list, render Craft markdown
fecrawl/cli.py        probe / discover / crawl / merge
selectors.toml        all site-specific rules live here, not in code
```

Site knowledge is confined to `selectors.toml`. When FE changes its markup,
re-run `probe` and edit the config; the code does not change.

## Tests

```sh
python -m pytest tests/ -q
```

Covers dedupe against strings taken from the live Craft list, the extraction
rule engine against both table-and-label and run-on layouts, and the merge
invariants (no duplicates added, no existing entry dropped, genres filled).
