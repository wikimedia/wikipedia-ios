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

    public func updateAppIcon(isNew: Bool, completion: ((Error?) -> Void)? = nil) {
        guard UIApplication.shared.supportsAlternateIcons else {
            completion?(nil)
            return
        }

        if isPastEndDate {
            resetToDefaultIcon()
            completion?(nil)
            return
        }

        let iconName: String? = isNew ? "contributor-app-icon" : nil

        UIApplication.shared.setAlternateIconName(iconName) { [weak self] error in
            let currentIcon = UIApplication.shared.alternateIconName ?? "nil (default)"
            self?.isNewIconOn = isNew
            DispatchQueue.main.async {
                // Ignore the LSIconAlertManager Code=35 error on iOS 26 simulator.
                // Please test on device, prob a Xcode 26 issue, can't find docs about it.
                completion?(nil)
            }
        }
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
