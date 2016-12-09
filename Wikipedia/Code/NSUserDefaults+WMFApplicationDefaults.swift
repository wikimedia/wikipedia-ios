import Foundation

let WMFReadingFontSizeLegacyKey = "ReadingFontSize"
let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"

@objc enum WMFFontSizeMultiplier: Int {
    case ExtraSmall = 70
    case Small = 80
    case Medium = 90
    case Large = 100
    case ExtraLarge = 110
    case ExtraExtraLarge = 130
    case ExtraExtraExtraLarge = 160
}

extension NSUserDefaults {
    public func wmf_migrateFontSizeMultiplier() {
        if let readingFontSize = self.objectForKey(WMFReadingFontSizeLegacyKey) as? NSNumber {
            if readingFontSize.integerValue != WMFFontSizeMultiplier.Large.rawValue {
                self.setInteger(readingFontSize.integerValue, forKey: WMFArticleFontSizeMultiplierKey)
            }
            self.removeObjectForKey(WMFReadingFontSizeLegacyKey)
        }
    }
    
    public func wmf_setArticleFontSizeMultiplier(fontSize: NSNumber) {
        self.setObject(fontSize, forKey: WMFArticleFontSizeMultiplierKey)
        self.synchronize()
    }
    
    public func wmf_articleFontSizeMultiplier() -> NSNumber {
        if let fontSize = self.objectForKey(WMFArticleFontSizeMultiplierKey) as? NSNumber {
            return fontSize
        } else {
            let preferredContentSizeCategory = UIApplication.sharedApplication().preferredContentSizeCategory
            switch preferredContentSizeCategory {
            case UIContentSizeCategoryExtraSmall:
                return NSNumber(integer: WMFFontSizeMultiplier.ExtraSmall.rawValue)
            case UIContentSizeCategorySmall:
                return NSNumber(integer: WMFFontSizeMultiplier.Small.rawValue)
            case UIContentSizeCategoryMedium:
                return NSNumber(integer: WMFFontSizeMultiplier.Medium.rawValue)
            case UIContentSizeCategoryLarge:
                return NSNumber(integer: WMFFontSizeMultiplier.Large.rawValue)
            case UIContentSizeCategoryExtraLarge:
                return NSNumber(integer: WMFFontSizeMultiplier.ExtraLarge.rawValue)
            case UIContentSizeCategoryExtraExtraLarge:
                return NSNumber(integer: WMFFontSizeMultiplier.ExtraExtraLarge.rawValue)
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
                return NSNumber(integer: WMFFontSizeMultiplier.ExtraExtraExtraLarge.rawValue)
            default:
                return NSNumber(integer:WMFFontSizeMultiplier.Large.rawValue)
            }
        }
    }
}
