import Foundation
import CocoaLumberjackSwift
extension DDLog {
    @objc public class func wmf_setSwiftDefaultLogLevel(_ level: UInt) {
        defaultDebugLevel = DDLogLevel(rawValue: level)!
    }
}
