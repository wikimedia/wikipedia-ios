import WMFData

@objc public class WMFDonateDataControllerWrapper: NSObject {

    private let dataController = WMFDonateDataController.shared

    @objc public var hasLocallySavedDonations: Bool {
        get {
            return dataController.hasLocallySavedDonations
        }
        set {
            dataController.hasLocallySavedDonations = newValue
        }
    }

    @objc public func deleteLocalDonationHistory() {
        dataController.deleteLocalDonationHistory()
    }

    @objc public static let shared = WMFDonateDataControllerWrapper()

    private override init() {
        super.init()
    }
}
