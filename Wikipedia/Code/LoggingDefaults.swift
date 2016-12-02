import Foundation
import CocoaLumberjackSwift
extension DDLog {
    public class func wmf_setSwiftDefaultLogLevel(level: UInt) {
        defaultDebugLevel = DDLogLevel(rawValue: level)!
    }
}
