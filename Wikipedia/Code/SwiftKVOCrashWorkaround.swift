import Foundation
import CocoaLumberjackSwift

// https://bugs.swift.org/browse/SR-6795
// https://github.com/apple/swift/pull/20103

@objc(WMFSwiftKVOCrashWorkaround)
class SwiftKVOCrashWorkaround: NSObject {
    @objc dynamic var observeMe: String = ""
    @objc func performWorkaround() {
        let observation = observe(\SwiftKVOCrashWorkaround.observeMe, options: [.new]) { (observee, change) in
            DDLogError("Shouldn't have changed: \(observee)")
        }
        observation.invalidate()
    }
}
