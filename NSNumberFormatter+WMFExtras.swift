import Foundation

extension NSNumberFormatter {
    
    
    public func localizedThousandsStringFromNumber(number: NSNumber) -> String {
        let doubleValue = number.doubleValue
        let absDoubleValue = abs(doubleValue)
        
        var adjustedDoubleValue: Double =  0
        var formatString: String = "$1"
        
        if absDoubleValue < 1000000 {
            adjustedDoubleValue = doubleValue/1000.0
            formatString = localizedStringForKeyFallingBackOnEnglish("number-thousands")
        } else if absDoubleValue < 1000000000 {
            adjustedDoubleValue = doubleValue/1000000.0
            formatString = localizedStringForKeyFallingBackOnEnglish("number-millions")
        } else {
            adjustedDoubleValue = doubleValue/1000000000.0
            formatString = localizedStringForKeyFallingBackOnEnglish("number-billions")
        }
        
        if let numberString = self.stringFromNumber(adjustedDoubleValue) {
            return formatString.stringByReplacingOccurrencesOfString("$1" , withString: numberString)
        } else {
            return ""
        }
    }
}
