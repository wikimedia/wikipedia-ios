# VisualEditor Oracle

Differential-testing infrastructure: runs the real upstream VisualEditor document
model in an offscreen WKWebView and round-trips Parsoid documents through it, so
the native Swift engine can be validated against the reference implementation.

## Setup (once)

```sh
git clone https://github.com/wikimedia/VisualEditor.git upstream
git -C upstream checkout "$(cat VE_PINNED_SHA)"
python3 generate_harness.py
python3 fetch_corpus.py
```

`upstream/`, `corpus/`, and `results/` are gitignored; `VE_PINNED_SHA` pins the
oracle version (re-pin deliberately, then re-run everything).

## Run

```sh
swift run_oracle.swift               # round-trip + idempotence check, writes results/
swift run_oracle.swift --dump-linear # also writes linear model dumps as fixtures
```

Exit code is non-zero if any document fails to convert. `results/summary.json`
holds per-document idempotence, linear model size, and node type counts.
