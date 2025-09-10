import UIKit

public final class AppIconUtility {
    
    static let shared = AppIconUtility()
    private init() {}
    
    private let iconKey = "yearInReviewNewIcon2025"
    
    public var isNewIconOn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: iconKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: iconKey)
            updateAppIcon(isNew: newValue)
        }
    }
    
    public func updateAppIcon(isNew: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        
        let iconName = isNew ? "ContributorAppIcon" : nil
        
        UIApplication.shared.setAlternateIconName(iconName) { _ in }
    }
    
    public func syncIconWithStoredPreference() {
        updateAppIcon(isNew: isNewIconOn)
    }
}
