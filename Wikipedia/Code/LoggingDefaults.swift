import Foundation
import CocoaLumberjackSwift
extension DDLog {
    @objc public class func wmf_setSwiftDefaultLogLevel(_ level: UInt) {
        dynamicLogLevel = DDLogLevel(rawValue: level)!
    }
}
