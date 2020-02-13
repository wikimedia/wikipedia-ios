import XCTest

final class FIFOCacheTest: XCTestCase {

    func testCacheValue() {
        let stringCache = WMFFIFOCache<NSString, NSString>()
        // Cache values
        stringCache.setObject(.testValue, forKey: .key1)
        stringCache.setObject(.testValue2, forKey: .key2)
        // Load values
        XCTAssertEqual(stringCache.object(forKey: .key1), .testValue)
        XCTAssertEqual(stringCache.object(forKey: .key2), .testValue2)

        let numberCache = WMFFIFOCache<NSNumber, NSNumber>()
        // Cache values
        numberCache.setObject(.testValue, forKey: .key)
        // Load values
        XCTAssertEqual(numberCache.object(forKey: .key), .testValue)
    }

    func testRemoveCacheValue() {
        let cache = WMFFIFOCache<NSString, NSString>()
        // Cache values
        cache.setObject(.testValue, forKey: .key1)
        cache.setObject(.testValue2, forKey: .key2)

        XCTAssertEqual(cache.object(forKey: .key1), .testValue)
        XCTAssertEqual(cache.object(forKey: .key2), .testValue2)
        // Remove object form cache
        cache.removeObject(forKey: .key1)
        XCTAssertNil(cache.object(forKey: .key1))
        XCTAssertEqual(cache.object(forKey: .key2), .testValue2)
    }

    func testClearCache() {
        let cache = WMFFIFOCache<NSString, NSString>()
        // Cache values
        cache.setObject(.testValue, forKey: .key1)
        cache.setObject(.testValue2, forKey: .key2)

        XCTAssertEqual(cache.object(forKey: .key1), .testValue)
        XCTAssertEqual(cache.object(forKey: .key2), .testValue2)

        cache.removeAllObjects()
        XCTAssertNil(cache.object(forKey: .key1))
        XCTAssertNil(cache.object(forKey: .key2))
    }

    func testCacheLimit() {
        let cache = WMFFIFOCache<NSNumber, NSNumber>()
        let limit: UInt = 10
        cache.countLimit = limit / 2

        // Set value to cache
        for number in 0 ..< limit {
            let keyAndValue = NSNumber(value: number)
            cache.setObject(keyAndValue, forKey: keyAndValue)
        }

        // Test value out of cache limit
        for number in 0 ..< (limit - cache.countLimit) {
            XCTAssertNil(cache.object(forKey: NSNumber(value: number)))
        }

        // Test values in cache limit
        for number in (limit - cache.countLimit) ..< limit {
            let keyAndValue = NSNumber(value: number)
            XCTAssertEqual(cache.object(forKey: keyAndValue), keyAndValue)
        }
    }
}

// MARK: - Test values

private extension NSString {
    static let key: NSString = "key"
    static let key1: NSString = "key1"
    static let key2: NSString = "key2"

    static let testValue: NSString = "value"
    static let testValue2: NSString = "value2 "
    static let `nil`: NSString? = nil
}

private extension NSNumber {
    static let key: NSNumber = NSNumber(integerLiteral: 1)
    static let testValue: NSNumber = NSNumber(integerLiteral: 2)
    static let `nil`: NSNumber? = nil
}
