import SwiftUI
import WMFData
import UserNotifications

@MainActor
public final class WMFPushNotificationsSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let headerText: String
        public let pushNotificationsTitle: String

        public init(title: String, headerText: String, pushNotificationsTitle: String) {
            self.title = title
            self.headerText = headerText
            self.pushNotificationsTitle = pushNotificationsTitle
        }
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var isPushEnabled: Bool = false
    @Published public var isLoading: Bool = true
    @Published public var permissionStatus: PermissionStatus = .notDetermined

    public enum PermissionStatus {
        case authorized
        case denied
        case notDetermined
    }

    public let localizedStrings: LocalizedStrings

    private let userDefaults: UserDefaults
    public var onRequestPermissions: (() -> Void)?
    public var onUnsubscribe: (() -> Void)?
    public var onOpenSystemSettings: (() -> Void)?

    public init(localizedStrings: LocalizedStrings, userDefaults: UserDefaults = .standard, onRequestPermissions: (() -> Void)? = nil, onUnsubscribe: (() -> Void)? = nil, onOpenSystemSettings: (() -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.userDefaults = userDefaults
        self.onRequestPermissions = onRequestPermissions
        self.onUnsubscribe = onUnsubscribe
        self.onOpenSystemSettings = onOpenSystemSettings

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        // Check permission status
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            permissionStatus = .authorized
            // Load subscription status from UserDefaults
            isPushEnabled = userDefaults.bool(forKey: "WMFIsSubscribedToEchoNotifications")
        case .notDetermined:
            permissionStatus = .notDetermined
            isPushEnabled = false
        case .denied:
            permissionStatus = .denied
            isPushEnabled = false
        @unknown default:
            permissionStatus = .notDetermined
            isPushEnabled = false
        }

        buildSections()
    }

    private func buildSections() {
        switch permissionStatus {
        case .authorized, .notDetermined:
            // Show toggle switch
            sections = [
                SettingsSection(
                    header: localizedStrings.headerText,
                    footer: nil,
                    items: [pushNotificationsToggleItem()]
                )
            ]
        case .denied:
            // Show link to system settings
            sections = [
                SettingsSection(
                    header: localizedStrings.headerText,
                    footer: nil,
                    items: [systemSettingsItem()]
                )
            ]
        }
    }

    private func pushNotificationsToggleItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.pushNotificationsTitle,
            subtitle: nil,
            accessory: .toggle(pushNotificationsBinding),
            action: nil
        )
    }

    private func systemSettingsItem() -> SettingsItem {
        SettingsItem(
            image: nil,
            color: nil,
            title: localizedStrings.pushNotificationsTitle,
            subtitle: nil,
            accessory: .chevron(label: nil),
            action: { [weak self] in
                self?.onOpenSystemSettings?()
            }
        )
    }

    private var pushNotificationsBinding: Binding<Bool> {
        Binding(
            get: { self.isPushEnabled },
            set: { newValue in
                Task { @MainActor in
                    await self.setPushEnabled(newValue)
                }
            }
        )
    }

    public func setPushEnabled(_ newValue: Bool) async {
        if newValue {
            // Request permissions
            onRequestPermissions?()
        } else {
            // Unsubscribe
            isPushEnabled = false
            userDefaults.set(false, forKey: "WMFIsSubscribedToEchoNotifications")
            onUnsubscribe?()
        }
        
        // Reload to update UI based on new permission status
        await loadAndBuild()
    }

    public func refreshAfterPermissionRequest(granted: Bool) async {
        if granted {
            isPushEnabled = true
            userDefaults.set(true, forKey: "WMFIsSubscribedToEchoNotifications")
        }
        await loadAndBuild()
    }
}
