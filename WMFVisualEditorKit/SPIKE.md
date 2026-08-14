# Native Visual Editor — Spike Results

**Branch:** `spike/native-visual-editor` · **Date:** 2026-08-13/14

This spike de-risks the two foundational bets of a native visual editor before any
larger investment, and ships a runnable in-app demo. It is evidence for an RFC,
not the start of a committed project.

## Bet 1 — Can the real VisualEditor serve as a test oracle? ✅

We run the **actual upstream VisualEditor document model** (`ve.dm`) inside an
offscreen WKWebView and round-trip real Parsoid documents through it:

```
Oracle/
  generate_harness.py   # resolves 391 scripts from upstream build/modules.json (no npm/grunt needed)
  fetch_corpus.py       # downloads Parsoid HTML seed corpus (12 docs, 6 wikis, LTR/RTL/CJK)
  run_oracle.swift      # WKWebView runner: HTML → linear model → HTML, twice per doc
  harness/oracle.js     # the in-page oracle API
  VE_PINNED_SHA         # upstream commit the oracle is pinned to
```

Results (see `Oracle/results/summary.json` after running):

- **12/12 documents converted with zero failures** (en, pt, ar, he, ja, zh).
- **12/12 idempotent**: the second round-trip is byte-identical to the first.
  This is the invariant our future Swift serializer will be tested against.
- **0/12 byte-identical to the original input**: VE normalizes serialization
  (attribute encoding etc.) on first conversion. Expected — and exactly why the
  engine must use *selective serialization* (untouched nodes emit original
  bytes) rather than relying on converter fidelity. Confirmed early, cheaply.
- Conversion also runs fast enough to fuzz at scale (≤0.1s per document).

To reproduce: `git clone` the pinned upstream into `Oracle/upstream`, then
`python3 generate_harness.py && python3 fetch_corpus.py && swift run_oracle.swift`.
Add `--dump-linear` to write linear-model fixtures for differential tests.

## Bet 2 — Is a small exact parser viable for Parsoid HTML? ✅

`WMFVisualEditorKit` (new SPM package, **Swift 6 language mode, strict
concurrency, zero dependencies**) contains the first engine slice:

- `WMFParsoidHTMLParser` — exact tokenizer/tree parser for Parsoid's
  machine-serialized HTML. Not an HTML5 recovery parser by design: malformed
  input throws instead of being silently "fixed" (which would corrupt content
  on round-trip). Preserves everything: attribute order, `data-mw`,
  `data-parsoid`, RDFa `typeof`, unknown elements.
- `WMFVisualEditorLinearModelBuilder` — tree → linear model (ve.dm-style open/
  close/annotated-character items) for the understood subset: sections,
  paragraphs, headings, lists, bold/italic/link annotations. Everything else
  becomes an **alien/transclusion node carrying its full original subtree** —
  opaque in the editor, byte-preserved for round-trip.
- 14 tests, including two checked-in real Parsoid fixtures (pt, zh). The zh
  fixture is deliberately template-heavy (57KB with a single `<p>`) — a useful
  reminder that on some wikis nearly the whole page is opaque nodes.

## The in-app demo

Choosing **Visual** in the edit flow (always offered in debug builds; behind
`enableVisualEditingJourney` otherwise) opens the **Native VE Playground**: it
fetches the article's Parsoid HTML (the same document web VE edits), parses it
through the native engine, and renders the linear model natively — no web view
anywhere. Templates/figures render as `⧉` placeholder chips with excerpts:
visibly *preserved, not interpreted*.

**Editing is live**: every keystroke maps through a rendered-text → linear-model
index map and becomes a character-level transaction (`replacingCharacters`),
with exact undo/redo (removed items are restored annotations-and-all). Edits
that would touch structure or opaque nodes are rejected at the model layer.
The ⓘ button shows the model inspector (node counts, parse time, edit count).

## The null-edit gate: PASSED ✅

The selective serializer (engine chunk 2.4) is implemented and holds the
project's core invariant:

- **Parse → serialize with zero edits is byte-identical on 12/12 corpus
  documents** (en, pt, ar, he, ja, zh — real articles, full documents including
  head). Verified by unit tests on the checked-in fixtures and by the corpus
  runner.
- How: every parsed node carries its exact source range; the builder drops
  nothing (inter-block whitespace, comments, styles and metas become invisible
  `meta` items; wrappers become `container` items); edits mark their enclosing
  blocks dirty; the serializer emits clean subtrees byte-for-byte from source
  and re-serializes only dirty blocks (with their original element names and
  ordered attributes — `rel="mw:WikiLink"` on links survives editing).
- Structural edits participate: paragraph splits serialize as two paragraphs;
  undone edits stay conservatively dirty (normalized, not byte-identical) but
  always reparse — a candidate refinement, not a correctness issue.

This unblocks the save pipeline: serialized HTML → server `html→wikitext`
transform → existing save flow.

## What this spike still does not do

- Save pipeline wiring (next: serialize + transform + EditSave flow).
- Block merge on Backspace (inverse of split), multi-block paste.
- Marked-text/IME composition — the TextKit 2 phase.
- Differential Swift-vs-oracle comparison of the *linear model* (fixtures and
  pinned oracle exist for this; null-edit fidelity is currently the stronger,
  passing gate).
- Corpus is 12 seed documents, not the 5k-document gate from the plan.

## Open decisions for the RFC

1. Commit to the ~9–15 month native plan, keep improving the web kick-out
   return journey (T434236), or embed web VE in a WKWebView — this spike only
   prices the first option's foundations.
2. Offline editing in or out of scope (it is the strongest argument for native).
3. Hand-rolled exact parser (this spike) vs. SwiftSoup dependency.
