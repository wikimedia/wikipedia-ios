### Updating languages

Inside the main project, there's a `languages` target that is a Mac command line tool. You can edit the swift files used by this target (inside `Command Line Tools/Update Languages/`) to update the languages script. Running the `Update Languages` scheme will create all of the needed config files for any new Wikipedia languages detected. You can then submit a PR with the changes generated. 

### Updating language variants
At present there is no automated process for adding language variants to the app. When a new language variant or set of language variants is added to the app there are two files that need to be updated:

1. The language variant definition file (`wikipedia-language-variants.json`).
2. The language variant mapping file (`MediaWikiAcceptLanguageMapping.json`).

#### Language variant definition file
The `wikipedia-language-variants.json` file is maintained manually. The file is keyed by Wikipedia language code with the value for each key being an array of language variants for that language. It is in this format because at runtime the Wikipedia language needs to be replaced by its variants.

For a language with existing language variants, add new variants to the existing array for that language.

For a language that has not had language variants before, add a new top-level key with the Wikipedia language code for the language with variants with the value being an array of the variants. Follow the pattern already established in the file.

_Troubleshooting: Variants missing from this file will not appear in the user's choices of langugages._ 

#### Language variant mapping file
During onboarding, the app uses the user's OS langauge preferences to suggest the preferred languages for Wikipedia content. If the language is one with variants, the variant specified by the user should be used.

However, the codes used by the OS to represent variants is different than the codes used by Wikipedia sites. The mapping from OS Locale for a given language to the Wikipedia language variant code is defined in the  `MediaWikiAcceptLanguageMapping.json` file.

The `MediaWikiAcceptLanguageMapping.json` file is a set of nested dictionaries. The keys in these dictionaries are the `languageCode`, `scriptCode`, and `regionCode` of the Locale corresponding to an OS preferred language. Each dictionary also has a `default` key in case no matching value is found.

When adding a new variant, the correct mapping from the OS language / Locale to that variant should be added to this file.

_Troubleshooting: Variants missing from this file cause onboarding to fail to identify a variant to suggest to the user ._ 

Note: Historically this mapping file was used to determine the user's language variant preference in Chinese and Serbian based on the user's OS language settings. The new language variant feature allows the user to choose variants explicitly.

#### Locale to language variant mapping details
A locale identifier in the OS can include:

- A language identifier on its own. For example: "zh" for _Chinese_.

- Language and script identifiers. For example: "sr_Cyrl" for _Serbian, Cryillic_; "sr_Latn" for _Serbian, Latin_

- Language, script, and region identifiers. For example: "zh_Hant_TW" for _Taiwanese, Traditional_; "zh_Hans_HK" for _Hong Kong, Simplified_

In Chinese, the region affects the Wikipedia langauge variant. So, the mapping file specifies regions in the most deeply nested dictionary.

In all other languages with variants so far, the script identifier is enough to identify the variant, and does not change regardless of region.
For these languages, only the "default" key is present in the region dictionary.

#### Other Locale to language variant mapping notes:

These notes are valid as of iOS 14.4

Not all scripts/variants supported by a particular Wikipedia language are available identifiers in the OS.
In these cases, finding the language in the user's OS preferences implies a particular language variant.

Gan "gan" and Crimean Tatar "crh" do not appear as available locale identifiers in the OS, although their scripts are. A default language variant value is provided in case a future OS includes these locale identifiers.

The OS does include locale identifiers for Kurdish "ku", but it does not seem to be a choice for users in language settings. Language variants for these identifiers is specified in the mapping although it does not currently seem to be selectable by the user.

Note that in Uzbek, the OS supports an Arabic variant of the language which is not present as a language variant for the Uzbek Wikipedia. In this case, the variant falls back to Latin, which is the most prevalent script in the untransformed articles on the Uzbek site.












