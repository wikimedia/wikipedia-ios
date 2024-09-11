import Foundation

public struct WMFDonateConfig: Codable {
    let version: Int
    public let currencyMinimumDonation: [String: Decimal]
    public let currencyMaximumDonation: [String: Decimal]
    public let currencyAmountPresets: [String: [Decimal]]
    public let currencyTransactionFees: [String: Decimal]
    public let countryCodeEmailOptInRequired: [String]
    public let countryCodeApplePayEnabled: [String]
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

    public func getMaxAmount(for currencyCode: String) -> Decimal {
        var max = currencyMaximumDonation[currencyCode] ?? Decimal()

        if max.isZero {
            if let defaultMin = currencyMinimumDonation["USD"], let defaultMax = currencyMaximumDonation["USD"], let currencyMin = currencyMinimumDonation[currencyCode] {
                max = currencyMin / defaultMin * defaultMax
            }
        }
        return max
    }
}
