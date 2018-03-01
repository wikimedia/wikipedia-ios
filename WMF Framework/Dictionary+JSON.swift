import Foundation

extension Dictionary {
    public func wmf_iso8601DateValue(for key: Key) -> Date? {
        guard let value = self[key] as? String else {
            return nil
        }
        return DateFormatter.wmf_iso8601().date(from: value)
    }
}
