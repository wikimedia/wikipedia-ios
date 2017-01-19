import XCTest
@testable import Wikipedia

class QuadKeyTests: XCTestCase {

    func testQuadKeys() {
        var p: QuadKeyPrecision = 1
        while p <= 32 {
            var lat: QuadKeyDegrees = -90
            while lat <= 90 {
                var lon: QuadKeyDegrees = -180
                while lon <= 180 {
                    let latPart = QuadKeyPart(latitude: lat, precision: p)
                    let lonPart = QuadKeyPart(longitude: lon, precision: p)
                    let quadKey = QuadKey(latitudePart: latPart, longitudePart: lonPart, precision: p)
                    let altQuadKey = QuadKey(latitude: lat, longitude: lon, precision: p)
                    XCTAssertEqual(quadKey, altQuadKey, "QuadKeys should match no matter how they were calculated")
                    let fullPrecisionLatPart = QuadKeyPart(latitude: lat)
                    let fullPrecisionLonPart = QuadKeyPart(longitude: lon)
                    let fullPrecisionQuadKey = QuadKey(latitude: lat, longitude: lon)
                    let adjustedQuadKey = fullPrecisionQuadKey.adjusted(downBy: 32 - p)
                    XCTAssertEqual(quadKey, adjustedQuadKey, "QuadKeys should match no matter how they were calculated\n\(adjustedQuadKey.bitmaskString)\n\(quadKey.bitmaskString)\n\(fullPrecisionQuadKey.bitmaskString)\n\n\(fullPrecisionLatPart.bitmaskString)\n\(latPart.bitmaskString)\n\n\(fullPrecisionLonPart.bitmaskString)\n\(lonPart.bitmaskString)")
                    let bounds = QuadKeyBounds(quadKey: adjustedQuadKey, precision: p)
                    XCTAssertGreaterThanOrEqual(fullPrecisionQuadKey, bounds.min)
                    XCTAssertLessThanOrEqual(fullPrecisionQuadKey, bounds.max)
                    let coord = QuadKeyCoordinate(quadKey: quadKey, precision: p)
                    XCTAssertEqual(coord.latitudePart, latPart, "latPart: \(latPart) != \(coord.latitudePart)")
                    XCTAssertEqual(coord.longitudePart, lonPart, "lonPart: \(lonPart) != \(coord.longitudePart)")
                    let calculatedLat = QuadKeyDegrees(latitudePart: coord.latitudePart, precision: p)
                    let calculatedLon = QuadKeyDegrees(longitudePart: coord.longitudePart, precision: p)
                    XCTAssertEqualWithAccuracy(calculatedLat, lat, accuracy: p.deltaLatitude, "latitude is wrong at poom level \(p)")
                    XCTAssertEqualWithAccuracy(calculatedLon, lon,  accuracy: p.deltaLongitude, "longitude is wrong at poom level \(p)")
                    
                    if p == 32 {
                        let fullPrecision = QuadKeyPrecision(32)
                        let fullPrecisionCoord = QuadKeyCoordinate(quadKey: fullPrecisionQuadKey)
                        let fullPrecisionCalculatedLat = QuadKeyDegrees(latitudePart: fullPrecisionCoord.latitudePart)
                        let fullPrecisionCalculatedLon = QuadKeyDegrees(longitudePart: fullPrecisionCoord.longitudePart)
                        XCTAssertEqualWithAccuracy(fullPrecisionCalculatedLat, lat, accuracy: fullPrecision.deltaLatitude, "full poom latitude is wrong")
                        XCTAssertEqualWithAccuracy(fullPrecisionCalculatedLon, lon,  accuracy: fullPrecision.deltaLongitude, "full poom longitude is wrong")
                    }
                    lon += 1.5
                }
                lat += 1.5
            }
            p += 1
        }

    }
    
}
