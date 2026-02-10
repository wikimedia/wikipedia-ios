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

}
