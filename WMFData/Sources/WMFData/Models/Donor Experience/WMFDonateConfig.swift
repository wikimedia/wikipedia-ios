import Foundation

public struct WMFDonateConfig: Codable {
    let version: Int
    public let currencyMinimumDonation: [String: Decimal]
    public let currencyMaximumDonation: [String: Decimal]
    public let currencyAmountPresets: [String: [Decimal]]
    public let currencyTransactionFees: [String: Decimal]
    public let countryCodeEmailOptInRequired: [String]
    var cachedDate: Date?
    
    public func transactionFee(for currencyCode: String) -> Decimal? {
        return currencyTransactionFees[currencyCode] ?? currencyTransactionFees["default"]
    }
}
