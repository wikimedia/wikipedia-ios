import UIKit

public extension WMFFont {
    
    static var navigationBarCloseButtonFont: WMFFont {
        return .mediumSubheadline
    }
    
    static var navigationBarLeadingCompactTitleFont: UIFont {
        return WMFFont.for(.boldTitle1)
    }
    
    static var navigationBarLeadingLargeTitleFont: UIFont {
        return WMFFont.for(.boldTitle1)
    }
    
    static var navigationBarCustomLeadingLargeTitleFont: UIFont {
        let largeTraitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        return WMFFont.for(.boldTitle1, compatibleWith: largeTraitCollection)
    }
}
