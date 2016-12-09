import Foundation

extension NSUserDefaults {
    public func wmf_setArticleFontSizeMultiplier(fontSize: NSNumber) {
        self.setObject(fontSize, forKey: "ReadingFontSize")
        self.synchronize()
    }
    
    public func wmf_articleFontSizeMultiplier() -> NSNumber {
        if let fontSize = self.objectForKey("ReadingFontSize") as? NSNumber {
            return fontSize
        } else {
            let preferredContentSizeCategory = UIApplication.sharedApplication().preferredContentSizeCategory
            switch preferredContentSizeCategory {
            case UIContentSizeCategoryExtraSmall:
                fallthrough
            case UIContentSizeCategorySmall:
                return NSNumber(integer: 70)
            case UIContentSizeCategoryMedium:
                return NSNumber(integer: 85)
            case UIContentSizeCategoryLarge:
                return NSNumber(integer: 100)
            case UIContentSizeCategoryExtraLarge:
                return NSNumber(integer: 115)
            case UIContentSizeCategoryExtraExtraLarge:
                return NSNumber(integer: 130)
            case UIContentSizeCategoryAccessibilityMedium:
                fallthrough
            case UIContentSizeCategoryExtraExtraExtraLarge:
                return NSNumber(integer: 145)
            case UIContentSizeCategoryAccessibilityLarge:
                fallthrough
            case UIContentSizeCategoryAccessibilityExtraLarge:
                fallthrough
            case UIContentSizeCategoryAccessibilityExtraExtraLarge:
                fallthrough
            case UIContentSizeCategoryAccessibilityExtraExtraExtraLarge:
                return NSNumber(integer: 160)
            default:
                return NSNumber(integer:100)
            }
        }
    }
}
