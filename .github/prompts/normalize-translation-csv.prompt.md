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
- **File**: The `.lproj` directory name, derived from the input filename (e.g. `de.csv` or `reading challenge translations_de.csv` → `de.lproj`)

## Step 0: Resolve the input

The argument may be:
- **Omitted**: process all `.csv` files in `scripts/manual translations/raw/`
- **A directory path**: process all `.csv` files in that directory
- **A single file path**: process only that file

Build the list of files to process. All output CSVs go into `scripts/manual translations/normalized/` (create it if it doesn't exist).

Read `Wikipedia/Localizations/en.lproj/Localizable.strings` **once** before processing any files — reuse the same lookup table for all files.

## Step 1: Identify the language

Look at the input filename to determine the language code and target `.lproj` directory. Use this mapping for known edge cases:

| Filename fragment | File value  |
|-------------------|-------------|
| `_de`             | `de.lproj`  |
| `_es-la`          | `es.lproj`  |
| `_fr`             | `fr.lproj`  |
| `_ja`             | `ja.lproj`  |
| `_ms`             | `ms.lproj`  |
| `_pt-br`          | `pt-br.lproj` |

For any other language, use the language code from the filename directly (e.g. `_zh-hans` → `zh-hans.lproj`). Verify the directory exists in `Wikipedia/Localizations/` before proceeding.

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
- **Find the Translation column**: Look for a column whose header contains words like "translation", "translated", "target" (case-insensitive), or which is the only other substantial text column that isn't English.
- **Ignore extra columns**: Reference images, notes, comments, empty columns — skip all of these.
- **Strip leading/trailing whitespace** from all cell values.

## Step 4: Match each row to a key

For each row with a non-empty English value and non-empty Translation:

1. **Exact match**: Look up the English value in the map from Step 2. If found, use that key.
2. **Normalized match**: If no exact match, try with trailing punctuation stripped (`.`, `!`, `?`), and/or with minor whitespace normalization.
3. **No match**: Leave the Key cell **blank**. Do NOT guess or invent a key. The import script will skip blank-key rows with a warning — that is the correct behavior. These are rows that don't correspond to any app string (e.g. motivational copy variants, UI descriptions for designers).

**Special case — plural strings**: The English string `"{{PLURAL:$1|$1 day|$1 days}}"` appears in `en.lproj` as the value for `reading-challenge-streak-days`. The CSV will likely have human-readable variants like `"1 day"`, `"2 days"`, `"X days"`. These rows have a single corresponding key (`reading-challenge-streak-days`) whose value is a `{{PLURAL:...}}` template. The Translation for this key should be written in `{{PLURAL:$1|...|...}}` format — use the singular and plural forms from the CSV rows. For languages with no grammatical plural distinction (Japanese, Malay), use a single form: `{{PLURAL:$1|<translation>}}`.

**Special case — date placeholders**: Some English strings contain `[11 May]` or similar bracketed dates. These are placeholder variants of strings whose canonical form uses `$1` and `$2`. Match these to the same key as the non-bracketed form, and write the Translation using `$1`/`$2` in place of the bracketed values (e.g. `[11 May]` → `$1`, `[18 June]` → `$2`).

## Step 5: Deduplicate

If multiple rows produce the same Key, keep only the first occurrence and skip the rest.

## Step 6: Write the output

Save the result as a CSV file in `scripts/manual translations/normalized/`, named after the language code only (e.g. `de.csv`, `es-la.csv`). Use UTF-8 encoding, comma-separated, with a header row.

Rows with a blank Key are still included in the output (the import script skips them gracefully).

Repeat Steps 1–6 for every file in the input list.

After all files are processed, print a combined summary:
- How many rows were matched to a key
- How many rows were left with a blank key (and list the English strings for review)
- How many rows were skipped entirely (blank/header/decoration)
