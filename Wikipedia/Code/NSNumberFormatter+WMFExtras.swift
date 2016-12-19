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
        var formatString: String = "$1"
        
        if absDoubleValue > 1000000000 {
            adjustedDoubleValue = doubleValue/1000000000.0
            formatString = localizedStringForKeyFallingBackOnEnglish("number-billions")
        } else if absDoubleValue > 1000000 {
            adjustedDoubleValue = doubleValue/1000000.0
            formatString = localizedStringForKeyFallingBackOnEnglish("number-millions")
        } else if absDoubleValue > 1000 {
            adjustedDoubleValue = doubleValue/1000.0
            formatString = localizedStringForKeyFallingBackOnEnglish("number-thousands")
        }
        
        if formatString == "$1" { //check for opt-out translations
            adjustedDoubleValue = doubleValue
        }
        
        
        if let numberString = thousandsFormatter.string(from: NSNumber(value:adjustedDoubleValue)) {
            return formatString.replacingOccurrences(of: "$1" , with: numberString)
        } else {
            return ""
        }
    }
    
}
