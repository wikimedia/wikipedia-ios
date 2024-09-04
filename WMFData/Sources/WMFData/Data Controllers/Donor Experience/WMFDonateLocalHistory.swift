import Foundation

public final class WMFDonateLocalHistory: Codable {

    let donationTimestamp: String
    let donationType: DonationType
    let donationAmount: Decimal
    let isNative: Bool

    // MARK: Nested Types

    public enum DonationType: String, Codable {
        case oneTime
        case recurring
    }

    public init(donationTimestamp: String, donationType: DonationType, donationAmount: Decimal, isNative: Bool) {
        self.donationTimestamp = donationTimestamp
        self.donationType = donationType
        self.donationAmount = donationAmount
        self.isNative = isNative
    }

}
