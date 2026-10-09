import Foundation
import Combine

public enum WMFEditMode: String, Sendable {
    case visual
    case source
}

public actor WMFSettingsDataController: ObservableObject {
    public static let shared = WMFSettingsDataController()

    nonisolated private var userDefaultsStore: WMFKeyValueStore? {
        WMFDataEnvironment.current.userDefaultsStore
    }

    private var yirDataController: WMFYearInReviewDataController?
    let donationDataController: WMFDonateDataController?

    init(yirDataController: WMFYearInReviewDataController? = try? WMFYearInReviewDataController(),
                  donationDataController: WMFDonateDataController? = WMFDonateDataController()
    ) {
        self.yirDataController = yirDataController
        self.donationDataController = donationDataController
        
        NotificationCenter.default.addObserver(
            forName: WMFNSNotification.coreDataStoreSetup,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.handleCoreDataStoreSetup()
            }
        }
    }
    
    private func handleCoreDataStoreSetup() {
        if yirDataController == nil {
            yirDataController = try? WMFYearInReviewDataController()
        }
    }

    public func yirIsActive() -> Bool {
        guard let yirDataController else {
            return false
        }
        return yirDataController.yearInReviewSettingsIsEnabled
    }

    public func shouldShowYiRSettingsItem() -> Bool {
        guard let yirDataController else {
            return false
        }
        return yirDataController.shouldShowYearInReviewSettingsItem(countryCode: Locale.current.region?.identifier)
    }


    public func hasLocalDonations() -> Bool {
        guard let donationDataController else {
            return false
        }
        return donationDataController.hasLocallySavedDonations
    }

    public func deleteLocalDonations() async {
        guard let donationDataController else {
            return
        }
        donationDataController.deleteLocalDonationHistory()

        try? await yirDataController?.deletePersonalizedData(for: .donations)
    }


    public func setYirActive(_ enabled: Bool) async -> Bool {
        yirDataController?.yearInReviewSettingsIsEnabled = enabled

        if !enabled {
            try? await yirDataController?.deleteAllPersonalizedData()
        }

        return yirIsActive()
    }

    // MARK: - autoSignTalkPageDiscussions

    public nonisolated func autoSignTalkPageDiscussions() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue)) ?? true
    }

    public nonisolated func setAutoSignTalkPageDiscussions(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue, value: newValue)
    }

    public nonisolated func didMigrateAutoSignTalkPageDiscussions() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.didMigrateAutoSignTalkPageDiscussions.rawValue)) ?? false
    }

    public nonisolated func setDidMigrateAutoSignTalkPageDiscussions(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.didMigrateAutoSignTalkPageDiscussions.rawValue, value: newValue)
    }

    public nonisolated func hasStoredAutoSignTalkPageDiscussions() -> Bool {
        return UserDefaults.standard.object(forKey: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue) != nil
    }

    // MARK: - Search Settings

    public nonisolated func showSearchLanguageBar() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.showSearchLanguageBar.rawValue)) ?? false
    }

    public nonisolated func setShowSearchLanguageBar(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.showSearchLanguageBar.rawValue, value: newValue)
    }

    public nonisolated func openAppOnSearchTab() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.openAppOnSearchTab.rawValue)) ?? false
    }

    /// Synchronous on purpose: the app reads this value while it builds its tabs, and the launch
    /// migrations write it just before that. Returns whether the value was saved, so a migration
    /// can keep its source value and retry on the next launch when it was not.
    @discardableResult
    public nonisolated func setOpenAppOnSearchTab(_ newValue: Bool) -> Bool {
        guard let userDefaultsStore else { return false }
        do {
            try userDefaultsStore.save(key: WMFUserDefaultsKey.openAppOnSearchTab.rawValue, value: newValue)
            return true
        } catch {
            return false
        }
    }

	// MARK: - Immersive Mode

	/// Whether the reader opted to hide the system status bar. Missing or unreadable settings default to off.
	/// Synchronous because UIKit needs the preference while creating and laying out view controllers.
	public nonisolated func immersiveModeEnabled() -> Bool {
		return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.immersiveModeEnabled.rawValue)) ?? false
	}

	/// Saves the preference before the UI applies it, returning false if persistence is unavailable or fails.
	/// Keeping the write synchronous preserves the order of successive toggle changes.
	@discardableResult
	public nonisolated func setImmersiveModeEnabled(_ enabled: Bool) -> Bool {
		guard let userDefaultsStore else { return false }
		do {
			try userDefaultsStore.save(key: WMFUserDefaultsKey.immersiveModeEnabled.rawValue, value: enabled)
			return true
		} catch {
			return false
		}
	}

    // MARK: - Editing Preferences

    /// The editing mode the user prefers. Written both from the choose editor sheet and from the
    /// editing preferences settings screen. Users who have never picked one get visual editing.
    public nonisolated func defaultEditMode() -> WMFEditMode {
        guard let raw: String = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.defaultEditMode.rawValue)) ?? nil,
              let mode = WMFEditMode(rawValue: raw) else {
            return .visual
        }
        return mode
    }

    public nonisolated func setDefaultEditMode(_ newValue: WMFEditMode) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.defaultEditMode.rawValue, value: newValue.rawValue)
    }

    /// Whether the choose editor sheet should be skipped in favor of going straight to `defaultEditMode()`.
    /// Only the sheet's "Don't show this again" checkbox turns this on — changing the mode in settings does not.
    public nonisolated func skipChooseEditorSheet() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.skipChooseEditorSheet.rawValue)) ?? false
    }

    public nonisolated func setSkipChooseEditorSheet(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.skipChooseEditorSheet.rawValue, value: newValue)
    }
}
