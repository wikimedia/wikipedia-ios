import XCTest
@testable import Wikipedia

final class FIFOCacheTest: XCTestCase {

    func testCacheValue() {
        var stringCache = FIFOCache<String>()
        // Cache values
        stringCache[.key1] = String.testValue
        stringCache[.key2] = Int.testValue
        // Load values
        XCTAssertEqual(stringCache[.key1], String.testValue)
        XCTAssertEqual(stringCache[.key2], Int.testValue)

        var intCache = FIFOCache<Int>()
        // Cache values
        intCache[1] = String.testValue
        intCache[2] = Int.testValue
        // Load values
        XCTAssertEqual(intCache[1], String.testValue)
        XCTAssertEqual(intCache[2], Int.testValue)
    }

    func testRemoveCacheValue() {
        var cache = FIFOCache<String>()
        cache[.key] = String.testValue
        cache[.key2] = Int.testValue
        XCTAssertEqual(cache[.key], String.testValue)
        XCTAssertEqual(cache[.key2], Int.testValue)

        cache[.key] = String.nil

        XCTAssertNil(cache[.key] as String?)
        XCTAssertEqual(cache[.key2], Int.testValue)
    }

    func testClearCache() {
        var cache = FIFOCache<String>()
        cache[.key] = 1
        XCTAssertEqual(cache[.key], 1)

        cache.clear()
        XCTAssertNil(cache[.key] as Int?)
    }

    func testCacheLimit() {
        var cache = FIFOCache<Int>()
        let limit = 10
        cache.limit = limit / 2

        // Set value to cache
        for number in 0 ..< limit {
            cache[number] = number
        }

        // Test value out of cache limit
        for number in 0 ..< (limit - cache.limit) {
            XCTAssertNil(cache[number] as Int?)
        }

        // Test values in cache limit
        for number in (limit - cache.limit) ..< limit {
            XCTAssertEqual(cache[number], number)
        }
    }
}

// MARK: - Test values

private extension String {
    static let key = "key"
    static let key1 = "key1"
    static let key2 = "key2"

    static let testValue = "value"
    static let `nil`: String? = nil
}

private extension Int {
    static let testValue = 123
    static let `nil`: Int? = nil
}
