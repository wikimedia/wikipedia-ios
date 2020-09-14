import Foundation

extension Bundle {
    var isAppExtension: Bool {
        return bundleURL.pathExtension.caseInsensitiveCompare("appex") == .orderedSame
    }
}
