import XCTest
import WMF

let pressDuration = 0.1 // don't set this to too large a value or presses which happen to land on buttons will activate the button instead of letting the drag event bubble up

extension XCUIElement {
    @discardableResult func wmf_tap() -> Bool {
        guard exists else { return false }
        if isHittable {
            tap()
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0)).tap()
        }
        return true
    }
    func wmf_typeText(text: String) -> Bool {
        guard exists else { return false }
        typeText(text)
        return true
    }
    func wmf_waitUntilExists(timeout: TimeInterval = 10) -> XCUIElement? {
        if exists && isHittable {
            return self
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND isHittable = true"), object: self)], timeout: timeout)
        if result != .completed {
            return nil
        }
        return self
    }
    
    func wmf_firstButton(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement? {
        return buttons.wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }
    @discardableResult func wmf_tapFirstButton(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        if let firstButton = wmf_firstButton(withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert) {
            return firstButton.wmf_tap()
        } else {
            return false
        }
    }

    func wmf_firstStaticText(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement? {
        return staticTexts.wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }
    @discardableResult func wmf_tapFirstStaticText(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        if let firstStaticText = wmf_firstStaticText(withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert) {
            return firstStaticText.wmf_tap()
        } else {
            return false
        }
    }

    func wmf_firstSwitch(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement? {
        return switches.wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }
    @discardableResult func wmf_tapFirstSwitch(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> Bool {
        if let firstSwitch = wmf_firstSwitch(withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert) {
            return firstSwitch.wmf_tap()
        } else {
            return false
        }
    }
    
    @discardableResult func wmf_firstSearchField(withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false) -> XCUIElement? {
        return searchFields.wmf_firstElement(with: .placeholderValue, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: shouldConvert)
    }

    @discardableResult func wmf_tapFirstCloseButton() -> Bool {
        return wmf_tapFirstButton(withTranslationIn: ["close-button-accessibility-label"])
    }
    
    @discardableResult func wmf_tapFirstNavigationBarBackButton() -> Bool {
        let backButtonTapped = wmf_tapFirstButton(withTranslationIn: ["back", "back-button-accessibility-label", "home-title"])
        guard !backButtonTapped else {
            return backButtonTapped
        }
        // Needed because if the title is long, the back button sometimes won't have text, as seen on https://stackoverflow.com/q/38595242/135557
        if let button = navigationBars.buttons.element(boundBy: 0).wmf_waitUntilExists() {
            return button.wmf_tap()
        } else {
            return false
        }
    }
    
    @discardableResult func wmf_tapFirstCollectionViewCell() -> Bool {
        if let cell = collectionViews.children(matching: .cell).element(boundBy: 0).wmf_waitUntilExists() {
            return cell.wmf_tap()
        } else {
            return false
        }
    }

    @discardableResult func wmf_tapFirstTableViewCell() -> Bool {
        if let cell = tables.children(matching: .cell).element(boundBy: 0).wmf_waitUntilExists() {
            return cell.wmf_tap()
        } else {
            return false
        }
    }

    @discardableResult func wmf_scrollToTop() -> Bool {
        if let statusBar = statusBars.element(boundBy: 0).wmf_waitUntilExists() {
            let tapResult = statusBar.wmf_tap()
            return tapResult
        } else {
            return false
        }
    }
    
    func wmf_scrollElementToTop(element: XCUIElement, yOffset: CGFloat = 0.0) {
        let normalizedOffset = CGVector(
            dx: 0.5,
            dy: 0.0 /* 0.0 is important - in case only top of view is above bottom of screen! (if we were scrolling elements to bottom of screen this would need to be 1.0) */
        )
        let elementTopCoord = element.coordinate(withNormalizedOffset: normalizedOffset)
        elementTopCoord.press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0, dy: yOffset)))
    }
    
    func wmf_scrollDown(times: Int = 1, dragStartY: Double = 0.8) {
        for _ in 0 ..< times {
            // If dragStartY set to 1.0 it drags from very bottom of the screen which triggers an iPad task switcher and zooms out the app. So drag from a little above the very bottom - hence the 0.8 dragStartY default value.
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dragStartY)).press(forDuration: pressDuration, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0)))
        }
    }
    
    // Scrolls to first element for each ScrollItem key in single scrolling pass (i.e. without scrolling back to top between items).
    func wmf_scrollToFirstElements(matching type: XCUIElement.ElementType, yOffset: CGFloat, items: [ScrollItem], timeout seconds: Double = 180) {
        let start = Date()
        var keys = items.map{$0.key}
        scrollLoop: repeat {
            if let element = descendants(matching: type).wmf_firstElement(with: .label, withTranslationIn: keys, convertTranslationSubstitutionStringsToWildcards: true, timeout: 1) {
                if let item = items.first(where: {$0.predicate.evaluate(with: element.label)}) {
                    wmf_scrollElementToTop(element: element, yOffset: yOffset)
                    item.success(element)
                    if let index = keys.firstIndex(of: item.key) {
                        keys.remove(at: index)
                    }
                    continue scrollLoop // Need to skip `wmf_scrollDown()` because other elements may already be onscreen and we don't want to scroll any of them offscreen. This lets the next pass(es) through the loop catch 'em.
                }
            }
            wmf_scrollDown()
        } while (Date().timeIntervalSince(start) < seconds) && (!keys.isEmpty)
    }
}

private enum ElementPropertyType: String {
    case label
    case placeholderValue
    case `self`
    
    func predicate(for text: String) -> NSPredicate {
        return NSPredicate(format: "\(rawValue) ==[cd] %@", text)
    }
    func wildcardPredicate(for text: String) -> NSPredicate {
        var mutableText = text
        for i in 0...9 {
            mutableText = mutableText.replacingOccurrences(of: "%\(i)$@", with: "*")
        }
        mutableText = "*\(mutableText)*"
        return NSPredicate(format: "\(rawValue) like[cd] %@", mutableText)
    }
    
    func predicate(for texts: [String]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: texts.map{text in predicate(for: text)})
    }
    func wildcardPredicate(for texts: [String]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: texts.map{text in wildcardPredicate(for: text)})
    }
}

private extension XCUIElementQuery {
    func wmf_firstElement(with propertyType: ElementPropertyType, withTranslationIn keys: [String], convertTranslationSubstitutionStringsToWildcards shouldConvert: Bool = false, timeout: TimeInterval = 10) -> XCUIElement? {
        let translations = keys.map{key in WMFLocalizedString(key, value: "", comment: "")} // localization strings are copied into this scheme during a build phase: https://stackoverflow.com/a/38133902/135557
        let predicate = shouldConvert ? propertyType.wildcardPredicate(for: translations) : propertyType.predicate(for: translations)
        return matching(predicate).element(boundBy: 0).wmf_waitUntilExists(timeout: timeout)
    }
}

struct ScrollItem {
    let key: String
    let success: (XCUIElement) -> ()
    let predicate: NSPredicate
    init(key: String, success: @escaping (XCUIElement) -> ()) {
        self.key = key
        self.success = success
        self.predicate = ElementPropertyType.`self`.wildcardPredicate(for: WMFLocalizedString(key, value: "", comment: ""))
    }
}

extension XCUIApplication {
    func dismissPopover() {
        otherElements["PopoverDismissRegion"].tap()
    }
}
