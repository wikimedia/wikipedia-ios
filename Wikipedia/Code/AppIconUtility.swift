import UIKit

@objc public final class AppIconUtility: NSObject {
    
    @objc static let shared = AppIconUtility()
    
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
    
    public var isPastEndDate: Bool {
        if Date() > endDate {
            return true
        }
        return false
    }
    
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

        if isPastEndDate {
            resetToDefaultIcon()
            return
        }
        
        let iconName = isNew ? "ContributorAppIcon" : nil
        isNewIconOn = isNew
        UIApplication.shared.setAlternateIconName(iconName) { _ in }
    }
    
    @objc public func checkAndRevertIfExpired() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        if isPastEndDate, isNewIconOn {
            resetToDefaultIcon()
        }
    }
    
    private func resetToDefaultIcon() {
        UIApplication.shared.setAlternateIconName(nil) { _ in }
        isNewIconOn = false
    }
}
