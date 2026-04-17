---
description: "Normalize messy translation CSVs from the translations team into the clean English/Translation/Key/File format required by the import script. Pass a directory to process all CSVs in it, or a single file path. Defaults to scripts/manual translations/raw/ if no argument is given."
agent: "agent"
argument-hint: "Path to a raw CSV file or directory of raw CSVs (default: scripts/manual translations/raw/)"
---

You are normalizing raw translation CSV files from the Wikipedia iOS translations team into a clean format that can be consumed by the import script at `scripts/manual translations/import-normalized-translations.swift`.

## Target format

The output CSV must have exactly these four columns, in this order:

```
English,Translation,Key,File
```

- **English**: The original English string (copied from the input)
- **Translation**: The translated string (copied from the input)
- **Key**: The `Localizable.strings` key — looked up by matching English against `Wikipedia/Localizations/en.lproj/Localizable.strings`
- **File**: The `.lproj` directory name — derived from the input filename for single-language files, or from the translation column header for multi-language files (see Step 1)

## Step 0: Resolve the input

The argument may be:
- **Omitted**: process all `.csv` files in `scripts/manual translations/raw/`
- **A directory path**: process all `.csv` files in that directory
- **A single file path**: process only that file

Build the list of files to process. All output CSVs go into `scripts/manual translations/normalized/` (create it if it doesn't exist).

Read `Wikipedia/Localizations/en.lproj/Localizable.strings` **once** before processing any files — reuse the same lookup table for all files.

For each file, inspect its header row to determine whether it is a **single-language file** or a **multi-language file**:
- **Single-language**: has one translation column (a column whose header contains "translation", "translated", "target", or similar)
- **Multi-language**: has multiple translation columns — one per language (e.g. columns named "German", "French", "de", "fr", etc.)

Process each shape differently as described in Steps 1 and 3.

## Step 1: Identify the language(s)

**Single-language file**: Extract the language/region code from the filename (e.g. `de`, `es-la`, `pt-br`) and find the matching `.lproj` directory under `Wikipedia/Localizations/`. List the available `.lproj` directories and pick the best match — the code in the filename may not be an exact match to the directory name, so use your best judgement (e.g. a file tagged `es-la` might correspond to `es.lproj`). If no reasonable match exists, print a warning and skip the file.

**Multi-language file**: Ignore the filename for language detection. Instead, each translation column header names a language (e.g. "German", "de", "French (France)"). For each translation column, extract the language/region code from the header and find the matching `.lproj` directory under `Wikipedia/Localizations/` using the same best-match approach. Each translation column will produce one output CSV.

## Step 2: Build the English → Key lookup table

Read `Wikipedia/Localizations/en.lproj/Localizable.strings`. Parse every line of the form:

```
"key" = "value";
```

Build a map of English value → key. This is the source of truth for key lookup in Step 4.

## Step 3: Parse the raw CSV

The input CSV may be messy in unpredictable ways. Apply all of the following:

- **Ignore blank rows** (rows where every cell is empty or whitespace)
- **Ignore the header row** and any decoration/metadata rows at the top (rows with no recognizable English copy)
- **Find the English column**: Look for a column whose non-empty values appear in the English-to-key map, OR whose header contains words like "English", "copy", "source", "original" (case-insensitive). This is the English column.
- **Find the translation column(s)**:
  - *Single-language file*: find the one column whose header contains words like "translation", "translated", "target" (case-insensitive), or which is the only other substantial text column that isn't English.
  - *Multi-language file*: every column that isn't the English column, a notes/image/comment column, or blank is a translation column. Match each to a language as described in Step 1.
- **Ignore extra columns**: Reference images, notes, comments, empty columns — skip all of these.
- **Strip leading/trailing whitespace** from all cell values.

## Step 4: Match each row to a key

For each row with a non-empty English value and non-empty Translation:

1. **Exact match**: Look up the English value in the map from Step 2. If found, use that key.
2. **Normalized match**: If no exact match, try with trailing punctuation stripped (`.`, `!`, `?`), and/or with minor whitespace normalization.
3. **No match**: Leave the Key cell **blank** and tag the row as one of:
   - **"likely has app key"** — the string looks like real UI copy that would appear in `Localizable.strings` (e.g. button labels, titles, short descriptive text). These go into the ⚠️ action list.
   - **"no app key (expected)"** — the string is clearly content that wouldn't be a localizable app string (e.g. marketing copy, reward descriptions, designer annotations). These go into the ℹ️ skipped list.
   Do NOT guess or invent a key. The import script will skip blank-key rows with a warning — that is the correct behavior.

**Special case — plural strings**: The English string `"{{PLURAL:$1|$1 day|$1 days}}"` appears in `en.lproj` as the value for `reading-challenge-streak-days`. The CSV will likely have human-readable variants like `"1 day"`, `"2 days"`, `"X days"`. These rows have a single corresponding key (`reading-challenge-streak-days`) whose value is a `{{PLURAL:...}}` template. The Translation for this key should be written in `{{PLURAL:$1|...|...}}` format — use the singular and plural forms from the CSV rows. For languages with no grammatical plural distinction (Japanese, Malay), use a single form: `{{PLURAL:$1|<translation>}}`.

**Special case — date placeholders**: Some English strings contain `[11 May]` or similar bracketed dates. These are placeholder variants of strings whose canonical form uses `$1` and `$2`. Match these to the same key as the non-bracketed form, and write the Translation using `$1`/`$2` in place of the bracketed values (e.g. `[11 May]` → `$1`, `[18 June]` → `$2`).

## Step 5: Deduplicate

If multiple rows produce the same Key, keep only the first occurrence and skip the rest.

## Step 6: Write the output

Save the result as a CSV file in `scripts/manual translations/normalized/`, named after the language code only (e.g. `de.csv`, `es-la.csv`). Use UTF-8 encoding, comma-separated, with a header row.

Rows with a blank Key are still included in the output (the import script skips them gracefully).

Repeat Steps 1–6 for every file in the input list. For multi-language files, produce one output CSV per translation column.

After all files are processed, print a combined summary followed by categorized action items.

**Summary counts (one line per language):**
```
de.csv:  ✅ 47 matched  ⚠️ 6 needs review  ℹ️ 14 skipped (no app key)  🔇 243 blank rows
```

**Action items (things that need human review):**

Print each of the following sections only if there are entries to show.

### ⚠️ Unmatched — likely has an app key but matching failed
Strings that look like real UI copy but couldn't be matched to a key. These are the most important to review — either the string is worded slightly differently in `en.lproj`, or it needs a manual key assignment.
Format: `[lang] "English string"` — one per line.

### 🔁 Duplicate keys dropped
Rows where multiple CSV entries resolved to the same key — only the first was kept.
Format: `[lang] key: "kept translation" (dropped: "other translation")` — one per line.

### 🔢 Incomplete plurals
Plural groups where only one form (singular or plural) was found in the CSV — the `{{PLURAL:...}}` template could not be fully built.
Format: `[lang] key: got singular only / got plural only` — one per line.

### ❌ Missing translation
Rows where the English matched a key but the translation cell was empty.
Format: `[lang] key: "English string"` — one per line.

### ℹ️ Skipped — no app key (expected)
Strings that have no corresponding app key and were expected to be skipped. These do not need action — listed here just for transparency.
Format: `[lang] "English string"` — one per line. If there are more than 10, show the first 10 and a count of the rest.
