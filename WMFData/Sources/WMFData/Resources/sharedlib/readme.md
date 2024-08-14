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
wikitext, the wiki language code, as well as the targetNamespaces (e.g. ["File", "Image"]) and targetAltParameters (e.g. ["alt"]) and returns an array of
detected links that don't appear to have an alt text marking.

## Internationalization

Pass in your localized namespace and alt parameters into the targetNamespaces and targetAltParameters parameters.

```
    let result = try WMFWikitextUtils.missingAltTextLinks(text: wikitext, language: "de", targetNamespaces: ["Datei", "Bild", "Image"], targetAltParams: ["alternativtext", "alt"])
```

## Calling from Swift

This logic can be accessed through the public static `missingAltTextLinks` method under WMFWikitextUtils. This utility struct resides in the WMFData package. Under-the-hood this method leans on `WMFAltTextDetector`, which is a helper class that is responsible for pulling the javascript library from the WMFData bundle and calling into it with JavaScriptCore. The `missingAltTextLinks` returns an array of `MissingAltTextLink` structs, each with:

* `text` - string of the full link
* `offset`, `length` - UTF-16 offset and length of the full link within the input wikitext
* `file` - the extracted file name from the link, which may have spaces or case normalization needs. Should be suitable for putting into the wiki API for fetching URLs etc.

It should be safe to insert an `alt=blah` before the final "`]]`" in the link string.

## Testing

There's a node CLI test under `tests/`

Run `npm test` inside the `sharedlib` dir to run them.

A swift-side unit test confirms the JSC bridge works as expected and will run automatically.

## The files

Javascript files (library and node tests) reside in the `WMFData` > `Sources` > `WMFData` > `Resources` > `sharedlib` subdirectory.
The Swift utility method resides in `WMFData` > `Utility` > `WMFWikitextUtils+AltText.swift`.  
Swift tests are in `WMFData` > `Tests` > `WMFDataTests` > `WMFWikitextUtilsTests.swift`
