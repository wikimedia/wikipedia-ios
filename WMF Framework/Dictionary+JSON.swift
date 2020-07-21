import Foundation

extension Dictionary {
    public func wmf_iso8601DateValue(for key: Key) -> Date? {
        guard let value = self[key] as? String else {
            return nil
        }
        return DateFormatter.wmf_iso8601().date(from: value)
    }
}

// Needed for Event Platform Client:
extension Dictionary {
    enum JSONConversionError: Error {
        case failureConvertingJSONDataToString
    }
    func toJSONString() throws -> String {
       let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
       guard let jsonString = String(data: jsonData, encoding: .utf8) else {
          throw JSONConversionError.failureConvertingJSONDataToString
       }
       return jsonString
    }
    func toPrettyPrintJSONString() throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: self, options: [JSONSerialization.WritingOptions.prettyPrinted])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
           throw JSONConversionError.failureConvertingJSONDataToString
        }
        return jsonString
    }
}

// Needed for Event Platform Client:
extension Dictionary where Key == String, Value == [String] {
    /**
     * Convenience function that appends `value` to an existing string array, but only if that value does not
     * already exist in the array
     * - Parameter key: key under which to find or create the string array
     * - Parameter value: value to append to the string array or use as the first value of a new one
     */
    mutating func appendIfNew(key: String, value: String) {
        if var currentStringArray = self[key] {
            if !currentStringArray.contains(value) {
                currentStringArray.append(value)
                self[key] = currentStringArray
            }
        } else {
            self[key] = [value]
        }
    }
}
