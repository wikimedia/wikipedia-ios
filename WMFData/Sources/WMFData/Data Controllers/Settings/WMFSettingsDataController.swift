import Foundation
import Combine

public actor WMFSettingsDataController: ObservableObject {

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    let yirDataController: WMFYearInReviewDataController?
    let donationDataController: WMFDonateDataController?

    public init (yirDataController: WMFYearInReviewDataController? = try? WMFYearInReviewDataController(),
                 donationDataController: WMFDonateDataController? = WMFDonateDataController()
    ) {
        self.yirDataController = yirDataController
        self.donationDataController = donationDataController
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

    public func deleteLocalDonations() {
        guard let donationDataController else {
            return
        }
        donationDataController.deleteLocalDonationHistory()
    }


    public func setYirActive(_ enabled: Bool) async -> Bool {
        yirDataController?.yearInReviewSettingsIsEnabled = enabled

        return yirIsActive()
    }

    // MARK: - autoSignTalkPageDiscussions

    public func autoSignTalkPageDiscussions() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue)) ?? true
    }

    public func setAutoSignTalkPageDiscussions(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.autoSignTalkPageDiscussions.rawValue, value: newValue)
    }

    // MARK: - Search Settings

    public func showSearchLanguageBar() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.showSearchLanguageBar.rawValue)) ?? false
    }

    public func setShowSearchLanguageBar(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.showSearchLanguageBar.rawValue, value: newValue)
    }

    public func openAppOnSearchTab() -> Bool {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.openAppOnSearchTab.rawValue)) ?? false
    }

    public func setOpenAppOnSearchTab(_ newValue: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.openAppOnSearchTab.rawValue, value: newValue)
    }

}
