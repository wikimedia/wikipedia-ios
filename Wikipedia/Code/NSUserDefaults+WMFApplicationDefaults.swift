import Foundation

let WMFReadingFontSizeLegacyKey = "ReadingFontSize"
let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"

@objc enum WMFFontSizeMultiplier: Int {
    case extraSmall = 70
    case small = 80
    case medium = 90
    case large = 100
    case extraLarge = 125
    case extraExtraLarge = 150
    case extraExtraExtraLarge = 175
    
    var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .extraSmall:
            return UIContentSizeCategory.extraSmall
        case .small:
            return UIContentSizeCategory.small
        case .medium:
            return UIContentSizeCategory.medium
        case .large:
            return UIContentSizeCategory.large
        case .extraLarge:
            return UIContentSizeCategory.extraLarge
        case .extraExtraLarge:
            return UIContentSizeCategory.extraExtraLarge
        case .extraExtraExtraLarge:
            return UIContentSizeCategory.extraExtraExtraLarge
        }
    }
}

extension UserDefaults {
    @objc public func wmf_migrateFontSizeMultiplier() {
        if let readingFontSize = self.object(forKey: WMFReadingFontSizeLegacyKey) as? NSNumber {
            if readingFontSize.intValue != WMFFontSizeMultiplier.large.rawValue {
                self.set(readingFontSize.intValue, forKey: WMFArticleFontSizeMultiplierKey)
            }
            self.removeObject(forKey: WMFReadingFontSizeLegacyKey)
        }
    }
    
    @objc public func wmf_setArticleFontSizeMultiplier(_ fontSize: NSNumber) {
        self.set(fontSize, forKey: WMFArticleFontSizeMultiplierKey)
    }
    
    @objc public func wmf_articleFontSizeMultiplier() -> NSNumber {
        if let fontSize = self.object(forKey: WMFArticleFontSizeMultiplierKey) as? NSNumber {
            return fontSize
        } else {
            let preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
            switch preferredContentSizeCategory {
            case UIContentSizeCategory.extraSmall:
                return NSNumber(value: WMFFontSizeMultiplier.extraSmall.rawValue as Int)
            case UIContentSizeCategory.small:
                return NSNumber(value: WMFFontSizeMultiplier.small.rawValue as Int)
            case UIContentSizeCategory.medium:
                return NSNumber(value: WMFFontSizeMultiplier.medium.rawValue as Int)
            case UIContentSizeCategory.large:
                return NSNumber(value: WMFFontSizeMultiplier.large.rawValue as Int)
            case UIContentSizeCategory.extraLarge:
                return NSNumber(value: WMFFontSizeMultiplier.extraLarge.rawValue as Int)
            case UIContentSizeCategory.extraExtraLarge:
                return NSNumber(value: WMFFontSizeMultiplier.extraExtraLarge.rawValue as Int)
            case UIContentSizeCategory.accessibilityMedium:
                fallthrough
            case UIContentSizeCategory.accessibilityLarge:
                fallthrough
            case UIContentSizeCategory.accessibilityExtraLarge:
                fallthrough
            case UIContentSizeCategory.accessibilityExtraExtraLarge:
                fallthrough
            case UIContentSizeCategory.accessibilityExtraExtraExtraLarge:
                fallthrough
            case UIContentSizeCategory.extraExtraExtraLarge:
                return NSNumber(value: WMFFontSizeMultiplier.extraExtraExtraLarge.rawValue as Int)
            default:
                return NSNumber(value: WMFFontSizeMultiplier.large.rawValue as Int)
            }
        }
    }
}
