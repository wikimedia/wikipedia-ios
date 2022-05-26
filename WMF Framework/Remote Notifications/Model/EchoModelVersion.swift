import Foundation

/// Represents the identifier received in a remote push notification sent by the Echo push notifier service. Note this is a class with a static property instead of an enum to simplify the interoperability with Objective-C.
@objc public class EchoModelVersion: NSObject {
    @objc public static let current = "checkEchoV1"
}
