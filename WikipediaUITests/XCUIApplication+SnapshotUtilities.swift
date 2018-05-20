import XCTest

// This this uitest target sleeps - the app target this test target taps doesn't.
// This delay just give everything an extra moment to settle.
let sleepBeforeTap:UInt32 = 1

extension XCUIApplication {
    func wmf_dismissPopover() {
        sleep(sleepBeforeTap)
        otherElements["PopoverDismissRegion"].firstMatch.tap()
    }
    
    // Quick way to get button which works with non-EN langs too (vs. recording which only works for language recorded in)
    func wmf_button(key: String) -> XCUIElement {
        return buttons[wmf_localizedString(key: key)].firstMatch
    }
    
    // Quick way to tap button which works with non-EN langs too
    func wmf_tapButton(key: String) {
        sleep(sleepBeforeTap)
        wmf_button(key: key).tap()
    }
    
    func wmf_searchField(key: String) -> XCUIElement {
        return searchFields[wmf_localizedString(key: key)].firstMatch
    }
    
    func wmf_tapSearchField(key: String) {
        sleep(sleepBeforeTap)
        wmf_searchField(key: key).tap()
    }
    
    func wmf_staticText(key: String) -> XCUIElement {
        return staticTexts[wmf_localizedString(key: key)].firstMatch
    }
    
    func wmf_tapStaticText(key: String) {
        sleep(sleepBeforeTap)
        wmf_staticText(key: key).tap()
    }
    
    func wmf_tapUnlocalizedCloseButton() {
        sleep(sleepBeforeTap)
        buttons["close"].firstMatch.tap()
    }
    
    func wmf_tapFirstCollectionViewCell() {
        sleep(sleepBeforeTap)
        collectionViews.children(matching: .any).firstMatch.tap()
    }
    
    // Gets localized string from localized string key (so we can navigate the app regardless of lang).
    // ( localization strings are copied into this scheme during a build phase: https://stackoverflow.com/a/38133902/135557 )
    // there's surely a cleaner way to get this path than using all the re-tries below (perhaps using the localization methods in WMF framework?), but this works for the langs we're testing at the moment
    func wmf_localizedString(key: String) -> String {
        let bundle = Bundle(for: WikipediaUITests.self)
        
        // try first with deviceLanguage as-is - i.e. "en-US"
        var bundlePath = bundle.path(forResource:deviceLanguage, ofType: "lproj")
        
        // if no bundlePath try lower case (fixes Chinese)
        if bundlePath == nil {
            bundlePath = bundle.path(forResource:deviceLanguage.lowercased(), ofType: "lproj")
        }
        
        // if no bundlePath try with just the "en" part of "en-US"
        if bundlePath == nil {
            let lang = deviceLanguage.split(separator: "-").first // gets "en" from "en-US", for example
            if lang == nil {
                return ""
            }
            bundlePath = bundle.path(forResource:String(lang!), ofType: "lproj")
        }
        
        if bundlePath == nil {
            return ""
        }
        guard let localizationBundle = Bundle(path: bundlePath!) else {
            return ""
        }
        
        var translation = NSLocalizedString(key, bundle: localizationBundle, comment: "")
        
        if (translation == key || (translation.count == 0)) {
            let enBundlePath = bundle.path(forResource: "en", ofType: "lproj")
            translation = NSLocalizedString(key, bundle: Bundle(path: enBundlePath!)!, comment: "")
        }
        return translation
    }
}
