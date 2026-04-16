# Manual Translations

This directory contains manually provided translations and the script to import them into the app's `.strings` localization files.

## Directory Structure

```
manual translations/
    README.md                         ← this file
    import-manual-translations.swift  ← import script
    translations/
        de.csv      ← German
        es-la.csv   ← Spanish (Latin America)
        fr.csv      ← French
        ja.csv      ← Japanese
        ms.csv      ← Malay
        pt-br.csv   ← Portuguese (Brazil)
```

## Clean CSV Format

After normalization, each CSV in `translations/` will have exactly these four columns:

| Column        | Description |
|---------------|-------------|
| `English`     | The original English string (informational only, not written to the file) |
| `Translation` | The translated string to import |
| `Key`         | The `Localizable.strings` key (e.g. `reading-challenge-announcement-title`) |
| `File`        | The target `.lproj` directory name (e.g. `de.lproj`) |

Rows with a blank `Key` are intentional — they correspond to motivational/placeholder strings that have no app key and are skipped by the import script.

### Plurals

Plural strings use `{{PLURAL:$1|singular|plural}}` syntax. For languages with no plural distinction (Japanese, Malay), a single form is used: `{{PLURAL:$1|$1日}}`.

---

### Step 1: Normalize the raw CSVs

The raw CSV files from the translations team are messy — inconsistent columns, blank rows, extra metadata, etc. Use the Copilot prompt to clean them up automatically.

In VS Code, type `/normalize-translation-csv` in the Copilot chat and provide the path to the raw file. The prompt will:
- Auto-detect the English and Translation columns regardless of column order or naming
- Look up each English string in `en.lproj/Localizable.strings` to derive the correct `Key`
- Derive the `File` (`.lproj` name) from the filename
- Handle plural strings and date placeholders
- Save a clean `{lang-code}.csv` into `translations/`

Run this once per language file. Review the printed summary — any rows left with a blank key are either intentional (motivational copy with no corresponding app key) or worth a quick check.

### Step 2: Run the import script

From the project root (`wikipedia-ios/`):

```bash
swift "scripts/manual translations/import-manual-translations.swift" "scripts/manual translations/translations/"
```

The script will:
- Insert each translation alphabetically into the correct `Wikipedia/Localizations/{lang}.lproj/Localizable.strings` file
- **Skip** keys that already exist (prints a warning)
- **Skip** rows with a blank Key, Translation, or File (prints a warning)
- **Preserve** all existing comments (including `// Fuzzy` lines) in the strings files
- Print a summary of inserted / skipped / errors at the end

### Step 3: Run "Update Localizations" in Xcode

See the section below.

---

## Adding a New Language for Next Time

1. Get the raw translated CSV from the translation team.
2. Run `/normalize-translation-csv` on it to produce a clean `{lang-code}.csv` in `translations/`.
3. Verify the `.lproj` directory exists in `Wikipedia/Localizations/` — if not, add the language to the project first (see `docs/localization.md`).
4. Run the import script.

## Adding New Strings for Next Time

1. Get the updated translated CSVs from the translation team (with new rows added).
2. Run `/normalize-translation-csv` on each file.
3. Run the import script — it will only insert keys that don't already exist.

> **Note:** The script is safe to re-run. It will skip any keys that are already present in the strings files and only insert genuinely new entries.

## Final Step: Run "Update Localizations"

Importing the CSV translations into `Wikipedia/Localizations/` is not the last step. Those raw `.strings` files still need to be processed into the format consumed by the app and then copied into the `WMFNativeLocalizations` Swift package.

To do this, run the **Update Localizations** scheme in Xcode. It builds and runs the `localization` command-line tool, which reads the `.strings` files from `Wikipedia/Localizations/`, converts them from TranslateWiki format (resolving `{{PLURAL:...}}` syntax into `.stringsdict` plists and converting `$1`-style placeholders into iOS-native `%1$@` format strings), and writes the results into the `WMFNativeLocalizations` Swift package — where the app can actually use them.

**In Xcode:**
1. Select the **Update Localizations** scheme from the scheme picker.
2. Run it (⌘R). It will produce output in the console and complete quickly.

After it finishes, the translated strings will be fully wired up and ready to ship.
