import Foundation

public struct WKDonateConfig: Codable {
    let version: Int
    public let currencyMinimumDonation: [String: Decimal]
    public let currencyMaximumDonation: [String: Decimal]
    public let currencyAmountPresets: [String: [Decimal]]
    public let currencyTransactionFees: [String: Decimal]
    public let countryCodeEmailOptInRequired: [String]
    var cachedDate: Date?
    
    public func transactionFee(for currencyCode: String, amount: Decimal = 0.0) -> Decimal? {
        
        let percent: Double = 0.04
        let calculatedTransactionFee = ((Double(amount.description) ?? 0.0) * percent).rounded()
        
        var transactionFee: Decimal?
        
        if let minimumTransactionFee = currencyTransactionFees[currencyCode] {
            transactionFee = (Decimal(calculatedTransactionFee) > minimumTransactionFee) ? Decimal(calculatedTransactionFee) : minimumTransactionFee
        } else if let defaultTransactionFee = currencyTransactionFees["default"] {
            transactionFee = (Decimal(calculatedTransactionFee) > defaultTransactionFee) ? Decimal(calculatedTransactionFee) : defaultTransactionFee
        }
        
        return transactionFee
    }
}
