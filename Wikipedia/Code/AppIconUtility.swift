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
    
    private func updateAppIcon(isNew: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Device does not support alternate icons")
            return
        }
        
        let iconName = isNew ? nil : "ContributorAppIcon"
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Failed request to update the app’s icon: \(error.localizedDescription)")
            } else {
                print("App icon updated to: \(iconName ?? "Default")")
            }
        }
    }
    
    public func syncIconWithStoredPreference() {
        updateAppIcon(isNew: isNewIconOn)
    }
}
