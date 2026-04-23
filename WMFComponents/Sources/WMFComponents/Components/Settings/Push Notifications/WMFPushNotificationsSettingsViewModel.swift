import SwiftUI
import WMFData
import UserNotifications

@MainActor
public final class WMFPushNotificationsSettingsViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let headerText: String
        public let pushNotificationsTitle: String
        public let permissionErrorTitle: String
        public let permissionErrorMessage: String
        public let errorAlertDismissButton: String

        public init(title: String, headerText: String, pushNotificationsTitle: String, permissionErrorTitle: String, permissionErrorMessage: String, errorAlertDismissButton: String) {
            self.title = title
            self.headerText = headerText
            self.pushNotificationsTitle = pushNotificationsTitle
            self.permissionErrorTitle = permissionErrorTitle
            self.permissionErrorMessage = permissionErrorMessage
            self.errorAlertDismissButton = errorAlertDismissButton
        }
    }

    @Published public private(set) var sections: [SettingsSection] = []
    @Published public var isPushEnabled: Bool = false
    @Published public var isLoading: Bool = true
    @Published public var permissionStatus: PermissionStatus = .notDetermined
    @Published public var showPermissionError: Bool = false

    public enum PermissionStatus {
        case authorized
        case denied
        case notDetermined
    }

    public let localizedStrings: LocalizedStrings

    private let userDefaultsKey = WMFUserDefaultsKey.isSubscribedToEchoNotifications.rawValue
    private let userDefaultsStore: WMFKeyValueStore?
    public var onRequestPermissions: (() -> Void)?
    public var onUnsubscribe: (() -> Void)?
    public var onOpenSystemSettings: (() -> Void)?

    public init(localizedStrings: LocalizedStrings, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, onRequestPermissions: (() -> Void)? = nil, onUnsubscribe: (() -> Void)? = nil, onOpenSystemSettings: (() -> Void)? = nil) {
        self.localizedStrings = localizedStrings
        self.userDefaultsStore = userDefaultsStore
        self.onRequestPermissions = onRequestPermissions
        self.onUnsubscribe = onUnsubscribe
        self.onOpenSystemSettings = onOpenSystemSettings

        Task { await loadAndBuild() }
    }

    public func loadAndBuild() async {
        isLoading = true
        defer { isLoading = false }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            permissionStatus = .authorized
            isPushEnabled = (try? userDefaultsStore?.load(key: userDefaultsKey)) ?? false
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
            sections = [
                SettingsSection(
                    header: localizedStrings.headerText,
                    footer: nil,
                    items: [pushNotificationsToggleItem()]
                )
            ]
        case .denied:
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
            try? userDefaultsStore?.save(key: userDefaultsKey, value: false)
            onUnsubscribe?()
        }

        await loadAndBuild()
    }

    public func showPermissionRequestError() {
        showPermissionError = true
    }

    public func refreshAfterPermissionRequest(granted: Bool) async {
        if granted {
            isPushEnabled = true
            try? userDefaultsStore?.save(key: userDefaultsKey, value: true)
        }
        await loadAndBuild()
    }
}
