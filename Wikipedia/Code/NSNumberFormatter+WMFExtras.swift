import Foundation

extension NSNumberFormatter {
    
    public class var wholeNumberFormatter: NSNumberFormatter? {
        get {
            struct Static {
                static var onceToken: dispatch_once_t = 0
                static var formatter: NSNumberFormatter? = nil
            }
            
            dispatch_once(&Static.onceToken) {
                Static.formatter = NSNumberFormatter()
                Static.formatter?.numberStyle = .DecimalStyle
                Static.formatter?.maximumFractionDigits = 0
            }
            return Static.formatter
        }
    }
    
    public class func localizedThousandsStringFromNumber(number: NSNumber) -> String {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var formatter: NSNumberFormatter? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.formatter = NSNumberFormatter()
            Static.formatter?.numberStyle = .DecimalStyle
            Static.formatter?.maximumFractionDigits = 1
        }
        
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
        
        if let numberString = Static.formatter?.stringFromNumber(adjustedDoubleValue) {
            return formatString.stringByReplacingOccurrencesOfString("$1" , withString: numberString)
        } else {
            return ""
        }
    }
    
}
