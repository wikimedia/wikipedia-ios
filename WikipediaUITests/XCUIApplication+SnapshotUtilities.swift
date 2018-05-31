import XCTest
import WMF

let pressDuration = 0.1 // don't set this to too large a value or presses which happen to land on buttons will activate the button instead of letting the drag event bubble up

extension XCUIElement {
    func wmf_tap() -> Bool {
        guard exists else { return false }
        tap()
        return true
    }
    func wmf_typeText(text: String) -> Bool {
        guard exists else { return false }
        typeText(text)
        return true
    }
    func wmf_waitUntilExists(timeout: TimeInterval = 30) -> XCUIElement {
        if self.exists { return self }
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: self)], timeout: timeout)
        return self
    }
}

private enum ElementPropertyType: String {
    case label
    case placeholderValue
}

private extension XCUIElementQuery {
    // Used `element:boundBy:0` rather than `firstMatch` because the latter doesn't play nice with `exists` checking as of Xcode 9.3
    func wmf_firstElement(with propertyType: ElementPropertyType, equalTo text: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false, timeout: TimeInterval = 30) -> XCUIElement {
        guard shouldConvert else {
            return matching(NSPredicate(format: "\(propertyType.rawValue) == %@", text)).element(boundBy: 0).wmf_waitUntilExists(timeout: timeout)
        }
        var textToUse = text
        for i in 0...9 {
            textToUse = textToUse.replacingOccurrences(of: "%\(i)$@", with: "*")
        }
        textToUse = "*\(textToUse)*"
        return matching(NSPredicate(format: "\(propertyType.rawValue) like[cd] %@", textToUse)).element(boundBy: 0).wmf_waitUntilExists(timeout: timeout)
    }
}

extension XCUIApplication {
    func wmf_button(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return buttons.wmf_firstElement(with: .label, equalTo: wmf_localizedString(key: key), convertSubstitutionStringsToWildcards: shouldConvert)
    }
    func wmf_tapButton(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        return wmf_button(key: key, convertSubstitutionStringsToWildcards: shouldConvert).wmf_tap()
    }

    func wmf_staticText(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return staticTexts.wmf_firstElement(with: .label, equalTo: wmf_localizedString(key: key), convertSubstitutionStringsToWildcards: shouldConvert)
    }
    func wmf_tapStaticText(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        return wmf_staticText(key: key, convertSubstitutionStringsToWildcards: shouldConvert).wmf_tap()
    }

    func wmf_switch(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return switches.wmf_firstElement(with: .label, equalTo: wmf_localizedString(key: key), convertSubstitutionStringsToWildcards: shouldConvert)
    }
    func wmf_tapSwitch(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        return wmf_switch(key: key, convertSubstitutionStringsToWildcards: shouldConvert).wmf_tap()
    }
    
    func wmf_searchField(key: String, convertSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement {
        return searchFields.wmf_firstElement(with: .placeholderValue, equalTo: wmf_localizedString(key: key), convertSubstitutionStringsToWildcards: shouldConvert)
    }

    func wmf_tapCloseButton() -> Bool {
        let unlocalizedCloseButton = buttons.wmf_firstElement(with: .label, equalTo: "close", convertSubstitutionStringsToWildcards: false, timeout: 8)
        guard unlocalizedCloseButton.exists else {
            return buttons.wmf_firstElement(with: .label, equalTo: wmf_localizedString(key: "close-button-accessibility-label")).wmf_tap()
        }
        return unlocalizedCloseButton.wmf_tap()
    }
    
    func wmf_tapNavigationBarBackButton() -> Bool {
        let backButtonTapped = wmf_button(key: "back").wmf_tap()
        guard backButtonTapped else {
            // Needed because if the title is long, the back button sometimes won't have text, as seen on https://stackoverflow.com/q/38595242/135557
            return navigationBars.buttons.element(boundBy: 0).wmf_waitUntilExists().wmf_tap()
        }
        return backButtonTapped
    }
    
    func wmf_tapFirstCollectionViewCell() -> Bool {
        return collectionViews.children(matching: .cell).element(boundBy: 0).wmf_waitUntilExists().wmf_tap()
    }
    
    func wmf_scrollToTop() -> Bool {
        let tapResult = statusBars.element(boundBy: 0).wmf_waitUntilExists().wmf_tap()
        sleep(3) // Give it time to scroll up.
        return tapResult
    }
    
    func wmf_scrollElementToTop(element: XCUIElement) {
        let elementTopCoord = element.coordinate(withNormalizedOffset:CGVector(dx: 0.5, dy: 0.0))
        elementTopCoord.press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)))
    }
    
    func wmf_scrollDown() {
        let iPadSafeBottomDragStartY: Double = 0.8 // If set to 1.0 it drags from very bottom of the screen which triggers an iPad task switcher and zooms out the app. So drag from a little above the very bottom.
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: iPadSafeBottomDragStartY)).press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.0)))
    }
    
    func wmf_scrollToOtherElement(key: String, success: (XCUIElement) -> ()){
        let maxScrollSeconds: Double = 240
        let start = Date()
        repeat {
            let element = otherElements.wmf_firstElement(with: .label, equalTo: wmf_localizedString(key: key), convertSubstitutionStringsToWildcards: true, timeout: TimeInterval(1))
            if element.exists {
                wmf_scrollElementToTop(element: element)
                sleep(1)
                success(element)
                break
            }
            wmf_scrollDown()
        } while Date().timeIntervalSince(start) < maxScrollSeconds
    }
    
    // Gets localized string from localized string key (so we can navigate the app regardless of lang).
    // ( localization strings are copied into this scheme during a build phase: https://stackoverflow.com/a/38133902/135557 )
    func wmf_localizedString(key: String) -> String {
        return WMFLocalizedString(key, value: "", comment: "")
    }
}
