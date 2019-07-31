import Foundation

let thousandsFormatter = { () -> NumberFormatter in
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.roundingMode = .halfUp
    return formatter
}()

let threeSignificantDigitWholeNumberFormatterGlobal = { () -> NumberFormatter in
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.usesSignificantDigits = true
    formatter.maximumSignificantDigits = 3
    formatter.roundingMode = .halfUp
    return formatter
}()

extension NumberFormatter {
    
    public class var threeSignificantDigitWholeNumberFormatter: NumberFormatter {
        get {
            return threeSignificantDigitWholeNumberFormatterGlobal
        }
    }
    
    public class func localizedThousandsStringFromNumber(_ number: NSNumber) -> String {
        let doubleValue = number.doubleValue
        let absDoubleValue = abs(doubleValue)
        
        var adjustedDoubleValue: Double = doubleValue
        var formatString: String = "%1$@"
        
        if absDoubleValue > 1000000000 {
            adjustedDoubleValue = doubleValue/1000000000.0
            formatString = WMFLocalizedString("number-billions", value:"%1$@B", comment:"%1$@B - %1$@ is replaced with a number represented in billions. In English 'B' is commonly used after a number to indicate that number is in 'billions'. So the 'B' should be changed to a character or short string indicating billions. For example 5,100,000,000 would become 5.1B. If there is no simple translation for this in the target language, make the translation %1$@ with no other characters and the full number will be shown.")
        } else if absDoubleValue > 1000000 {
            adjustedDoubleValue = doubleValue/1000000.0
            formatString = WMFLocalizedString("number-millions", value:"%1$@M", comment:"%1$@M - %1$@ is replaced with a number represented in millions. In English 'M' is commonly used after a number to indicate that number is in 'millions'. So the 'M' should be changed to a character or short string indicating millions. For example 500,000,000 would become 500M. If there is no simple translation for this in the target language, make the translation %1$@ with no other characters and the full number will be shown.")
        } else if absDoubleValue > 1000 {
            adjustedDoubleValue = doubleValue/1000.0
            formatString = WMFLocalizedString("number-thousands", value:"%1$@K", comment:"%1$@K - %1$@ is replaced with a number represented in thousands. In English the letter 'K' is commonly used after a number to indicate that number is in 'thousands'. So the letter 'K' should be changed to a character or short string indicating thousands. For example 500,000 would become 500K. If there is no simple translation for this in the target language, make the translation %1$@ with no other characters and the full number will be shown. {{Identical|%1$@k}}")
        }
        
        if formatString == "%1$@" { //check for opt-out translations
            adjustedDoubleValue = doubleValue
        }
        
        
        if let numberString = thousandsFormatter.string(from: NSNumber(value:adjustedDoubleValue)) {
            return String.localizedStringWithFormat(formatString, numberString)
        } else {
            return ""
        }
    }
    
}
