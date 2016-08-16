
import Foundation

extension DDLog {
    public class func wmf_setSwiftDefaultLogLevel(_ level: UInt) {
        defaultDebugLevel = DDLogLevel(rawValue: level)!
    }
}
