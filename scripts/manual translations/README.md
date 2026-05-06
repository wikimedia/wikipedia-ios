# Manual Translations

This directory contains manually provided translations. Drop raw CSV files from the translations team directly here, then use the Copilot prompt to normalize and insert them into the app's `.strings` localization files.

## Directory Structure

```
manual translations/
    README.md   ← this file
    *.csv       ← raw CSV files from the translations team
```

## Workflow

### Step 1: Import translations

Drop the raw CSV file(s) from the translations team into this directory, then open Copilot Chat in VS Code (`⌃⌘I`) and run:

```
/import-manual-translations
```

The prompt handles both single-language files (one CSV per language) and multi-language files (one CSV with a column per language). Copilot will:
- Read `en.lproj/Localizable.strings` to match each English string to its key
- Handle plural rows, merged cells, and date placeholders
- Insert translations directly into the correct `Wikipedia/Localizations/{lang}.lproj/Localizable.strings` files
- Print a summary flagging anything it couldn't match for manual review

### Step 2: Run "Update Localizations" in Xcode

See the section below.

---

## Adding a New Language for Next Time

1. Get the raw translated CSV from the translation team and drop it into this directory.
2. Run `/import-manual-translations` in Copilot chat.
3. Verify the `.lproj` directory exists in `Wikipedia/Localizations/` — if not, add the language to the project first.

## Adding New Strings for Next Time

1. Get the updated translated CSV(s) from the translation team and drop them into this directory.
2. Run `/import-manual-translations` in Copilot chat — it will skip keys that already exist and only insert new ones.

## Final Step: Run "Update Localizations"

Inserting translations into `Wikipedia/Localizations/` is not the last step. Those raw `.strings` files still need to be processed into the format consumed by the app and then copied into the `WMFNativeLocalizations` Swift package.

To do this, run the **Update Localizations** scheme in Xcode. It builds and runs the `localization` command-line tool, which reads the `.strings` files from `Wikipedia/Localizations/`, converts them from TranslateWiki format (resolving `{{PLURAL:...}}` syntax into `.stringsdict` plists and converting `$1`-style placeholders into iOS-native `%1$@` format strings), and writes the results into the `WMFNativeLocalizations` Swift package — where the app can actually use them.

**In Xcode:**
1. Select the **Update Localizations** scheme from the scheme picker.
2. Run it (⌘R). It will produce output in the console and complete quickly.

After it finishes, the translated strings will be fully wired up and ready to ship.

