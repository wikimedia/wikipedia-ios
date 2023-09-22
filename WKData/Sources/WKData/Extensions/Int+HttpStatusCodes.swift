import Foundation

extension Int {
    var isHttpSuccess: Bool {
        return (200..<300).contains(self)
    }
}
