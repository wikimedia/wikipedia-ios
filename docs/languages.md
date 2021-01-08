### Updating languages

Inside the main project, there's a `languages` target that is a Mac command line tool. You can edit the swift files used by this target (inside `Command Line Tools/Update Languages/`) to update the languages script. 

When translations for a new language are added to the app:
1. Run the `Update Languages` scheme in XCode. This will create all of the needed config files for any new Wikipedia languages detected.
2. If the new language is not seen in the `Localizable.strings` and/or `Localizable.stringsdict` files, the actual language files may need to be added to the XCode project manually. Select the `Localizable.strings` file in the the Project Navigator, then `File` -> `Add Files to Wikipedia`. Select all the files in the `Wikipedia/iOS Native Localizations/[lang code].lproj` folder (`Localizable.strings`, `Localizable.stringsdict`, and/or `InfoPlist.strings`). Add them only to the `WMF` target. (Ideally this step can be incoporated into the script run in the first step, but given how rarely new languages are added, for the time being this is manual.) 
3. If the new language is still not seen in both the `Localizable.strings` and `Localizable.stringsdict` files, add an `InfoPlist.string` file in the language's folder with the line `"CFBundleDisplayName" = "Wikipedia";`. Add this file to the project (see step 2).  
4. Submit a PR with the changes. 

### Updating language variants
At present there is no automated process for adding language variants to the app. The `wikipedia-language-variants.json` file is maintained manually. The file is keyed by Wikipedia language code with the value for each key being an array of language variants for that language. It is in this format because at runtime the Wikipedia language needs to be replaced by its variants.

For a language with existing language variants, add new variants to the existing array for that language.

For a language that has not had language variants before, add a new top-level key with the Wikipedia language code for the language with variants with the value being an array of the variants. Follow the pattern already established in the file.
