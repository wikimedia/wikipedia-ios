import Foundation

extension NSUserDefaults {
    public func wmf_setReadingFontSize(fontSize: NSNumber) {
        self.setObject(fontSize, forKey: "ReadingFontSize")
        self.synchronize()
    }
    
    public func wmf_readingFontSize() -> NSNumber {
        if let fontSize = self.objectForKey("ReadingFontSize") as? NSNumber {
            return fontSize
        } else {
            let preferredContentSizeCategory = UIApplication.sharedApplication().preferredContentSizeCategory
            switch preferredContentSizeCategory {
            case UIContentSizeCategoryExtraSmall:
                return NSNumber(integer: 70)
            case UIContentSizeCategorySmall:
                return NSNumber(integer: 85)
            case UIContentSizeCategoryMedium:
                return NSNumber(integer: 100)
            case UIContentSizeCategoryLarge:
                return NSNumber(integer: 115)
            case UIContentSizeCategoryExtraLarge:
                return NSNumber(integer: 130)
            case UIContentSizeCategoryExtraExtraLarge:
                return NSNumber(integer: 145)
            case UIContentSizeCategoryAccessibilityMedium:
                fallthrough
            case UIContentSizeCategoryAccessibilityLarge:
                fallthrough
            case UIContentSizeCategoryAccessibilityExtraLarge:
                fallthrough
            case UIContentSizeCategoryAccessibilityExtraExtraLarge:
                fallthrough
            case UIContentSizeCategoryAccessibilityExtraExtraExtraLarge:
                fallthrough
            case UIContentSizeCategoryExtraExtraExtraLarge:
                return NSNumber(integer: 160)
            default:
                return NSNumber(integer:100)
            }
        }
    }
}
