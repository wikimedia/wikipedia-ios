import Foundation
import Combine

public actor WMFSettingsDataController: ObservableObject {

    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore

    let yirDataController: WMFYearInReviewDataController?

    public init (yirDataController: WMFYearInReviewDataController? = try? WMFYearInReviewDataController()) {
        self.yirDataController = yirDataController
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

    public func setYirActive(_ enabled: Bool) async -> Bool {
        // TODO:
        return true
    }

}
