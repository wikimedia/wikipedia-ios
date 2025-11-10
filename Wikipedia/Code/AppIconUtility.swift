import UIKit

public final class AppIconUtility {
    
    static let shared = AppIconUtility()
    private init() {}
    
    private let iconKey = "yearInReviewNewIcon2025"
    private let endDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 30
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current.date(from: components)!
    }()
    
    public var isNewIconOn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: iconKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: iconKey)
        }
    }
    
    public func updateAppIcon(isNew: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        if Date() > endDate {
            resetToDefaultIcon()
            return
        }
        
        let iconName = isNew ? "ContributorAppIcon" : nil
        isNewIconOn = isNew
        UIApplication.shared.setAlternateIconName(iconName) { _ in }
    }
    
    public func checkAndRevertIfExpired() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        if Date() > endDate, isNewIconOn {
            resetToDefaultIcon()
        }
    }
    
    private func resetToDefaultIcon() {
        UIApplication.shared.setAlternateIconName(nil) { _ in }
        isNewIconOn = false
    }
}
