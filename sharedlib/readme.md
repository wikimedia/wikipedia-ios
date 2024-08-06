# Sharedlib prototype for Wikipedia mobile app

Wrote some of the logic for missing alt text detection in
platform-agnostic JavaScript which can be called via JSC
on iOS, and presumably equivalent setup on Android, if we
use the same logic there.

If this is too much rigamarole, it's fine to convert this
code to straight Swift, but it might be worth trying out.

The alt text link parser is simplified and won't catch
complex cases with templates and such but should handle
all common hand-written links and generally ignore others.

The `missingAltTextLinks()` function takes a string with
wikitext, and the language name, and returns an array of
detected links that don't appear to have an alt text marking.

## Internationalization

Currently it's hardcoded to the English namespace and alt
keyword names, this needs to be expanded with a list of each
language's overrides so it can build the appropriate regexes.

## Calling from Swift

`SharedLib.swift` in `Utilities` has the wrapper interfaces
on the Swift side; `AltText` encapsulates a JSC VM and can
have its `missingAltTextLinks()` method called to return a
Swift array of `MissingAltTextLink` structs, each with:

* `text` - string of the full link
* `offset`, `length` - UTF-16 offset and length of the full link within the input wikitext
* `file` - the extracted file name from the link, which may have spaces or case normalization needs. Should be suitable for putting into the wiki API for fetching URLs etc.

It should be safe to insert an `alt=blah` before the final "`]]`" in the link string.

## Testing

There's a node CLI test under `tests/`

Run `npm test` inside `sharedlib` dir to run them.

A swift-side unit test confirms the JSC bridge works as expected and will run automatically.

## The files

The `sharedlib` subdirectory is included in the output bundle alongside the `assets`, and `.js` is loaded out of it when instantiating the wrapper class.
