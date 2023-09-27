import Foundation

public struct WKDonateConfig: Codable {
    let version: Int
    public let currencyMinimums: [String: Decimal]
    public let currencyMaximums: [String: Decimal]
    public let currencyAmounts7: [String: [Decimal]]
    public let currencyTransactionFees: [String: Decimal]
    public let countryCodeEmailOptInRequired: [String]
    
    public func transactionFee(for currencyCode: String) -> Decimal? {
        return currencyTransactionFees[currencyCode] ?? currencyTransactionFees["default"]
    }
}
