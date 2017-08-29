import XCTest

class QuadKeyTests: XCTestCase {

    func testQuadKeys() {
        //Iterate over a good sampling of latitudes and longitudes at given zoom levels to verify our quad key calculations
        var p: QuadKeyPrecision = 1
        while p <= 32 { // iterate precisions
            var lat: QuadKeyDegrees = -90
            while lat <= 90 { // iterate latitudes
                var lon: QuadKeyDegrees = -180
                while lon <= 180 { // iterate longitudes
                    let latPart = QuadKeyPart(latitude: lat, precision: p) //calculate the latitude part (the y coordinate of the quad key)
                    let lonPart = QuadKeyPart(longitude: lon, precision: p) //calculate the longitude part (the x coordinate of the quad key)
                    let quadKey = QuadKey(latitudePart: latPart, longitudePart: lonPart, precision: p) //calculate the QuadKey given the two parts
                    let altQuadKey = QuadKey(latitude: lat, longitude: lon, precision: p) //calculate the quad key directly from lat and lon
                    XCTAssertEqual(quadKey, altQuadKey, "QuadKeys should match no matter how they were calculated")
                    let fullPrecisionLatPart = QuadKeyPart(latitude: lat)
                    let fullPrecisionLonPart = QuadKeyPart(longitude: lon)
                    let fullPrecisionQuadKey = QuadKey(latitude: lat, longitude: lon) // Calculate the full precision quad key
                    let adjustedQuadKey = fullPrecisionQuadKey.adjusted(downBy: 32 - p) // Adjust the quad key to the given zoom level (lose precision)
                    XCTAssertEqual(quadKey, adjustedQuadKey, "QuadKeys should match no matter how they were calculated\n\(adjustedQuadKey.bitmaskString)\n\(quadKey.bitmaskString)\n\(fullPrecisionQuadKey.bitmaskString)\n\n\(fullPrecisionLatPart.bitmaskString)\n\(latPart.bitmaskString)\n\n\(fullPrecisionLonPart.bitmaskString)\n\(lonPart.bitmaskString)")
                    let bounds = QuadKeyBounds(quadKey: adjustedQuadKey, precision: p)
                    XCTAssertGreaterThanOrEqual(fullPrecisionQuadKey, bounds.min)
                    XCTAssertLessThanOrEqual(fullPrecisionQuadKey, bounds.max)
                    let signedInteger = Int64(quadKey: fullPrecisionQuadKey)
                    let signedMax = Int64(quadKey: bounds.max)
                    let signedMin = Int64(quadKey: bounds.min)
                    XCTAssertGreaterThanOrEqual(signedInteger, signedMin)
                    XCTAssertLessThanOrEqual(signedInteger, signedMax)
                    XCTAssertEqual(QuadKey(int64: signedInteger), fullPrecisionQuadKey)
                    let coord = QuadKeyCoordinate(quadKey: quadKey, precision: p)
                    XCTAssertEqual(coord.latitudePart, latPart, "latPart: \(latPart) != \(coord.latitudePart)")
                    XCTAssertEqual(coord.longitudePart, lonPart, "lonPart: \(lonPart) != \(coord.longitudePart)")
                    let calculatedLat = QuadKeyDegrees(latitudePart: coord.latitudePart, precision: p)
                    let calculatedLon = QuadKeyDegrees(longitudePart: coord.longitudePart, precision: p)
                    XCTAssertEqual(calculatedLat, lat, accuracy: p.deltaLatitude, "latitude is wrong at precision \(p)")
                    XCTAssertEqual(calculatedLon, lon,  accuracy: p.deltaLongitude, "longitude is wrong at precision \(p)")
                    
                    if p == 32 {
                        let fullPrecision = QuadKeyPrecision(32)
                        let fullPrecisionCoord = QuadKeyCoordinate(quadKey: fullPrecisionQuadKey)
                        let fullPrecisionCalculatedLat = QuadKeyDegrees(latitudePart: fullPrecisionCoord.latitudePart)
                        let fullPrecisionCalculatedLon = QuadKeyDegrees(longitudePart: fullPrecisionCoord.longitudePart)
                        XCTAssertEqual(fullPrecisionCalculatedLat, lat, accuracy: fullPrecision.deltaLatitude, "full precision latitude is wrong")
                        XCTAssertEqual(fullPrecisionCalculatedLon, lon,  accuracy: fullPrecision.deltaLongitude, "full precision longitude is wrong")
                    }
                    lon += 5.25
                }
                lat += 5.25
            }
            p += (p == 1 ? 3 : 4)
        }

    }
    
    func testInvalidQuadKeys() {
        var invalidKey = QuadKey(latitude: Double.nan, longitude: Double.nan)
        XCTAssertEqual(invalidKey.latitude, -90)
        XCTAssertEqual(invalidKey.longitude, -180)
        
        invalidKey = QuadKey(latitude: Double.signalingNaN, longitude: Double.signalingNaN)
        XCTAssertEqual(invalidKey.latitude, -90)
        XCTAssertEqual(invalidKey.longitude, -180)
        
        invalidKey = QuadKey(latitude: Double.infinity, longitude: Double.infinity)
        XCTAssertEqual(invalidKey.latitude, -90)
        XCTAssertEqual(invalidKey.longitude, -180)
        
        invalidKey = QuadKey(latitude: 90.00001, longitude: 180.00001)
        XCTAssertEqual(invalidKey.longitude, 180)
        XCTAssertEqual(invalidKey.latitude, 90)
        
        invalidKey = QuadKey(latitude: -90.01, longitude: -180.01)
        XCTAssertEqual(invalidKey.longitude, -180)
        XCTAssertEqual(invalidKey.latitude, -90)
        
        var validKey = QuadKey(latitude: 90, longitude: 180)
        XCTAssertEqual(validKey.longitude, 180)
        XCTAssertEqual(validKey.latitude, 90)
        
        validKey = QuadKey(latitude: -90, longitude: -180)
        XCTAssertEqual(validKey.longitude, -180)
        XCTAssertEqual(validKey.latitude, -90)
        
        validKey = QuadKey(latitude: -0.0, longitude: -0.0)
        XCTAssertEqual(validKey.longitude, 0, accuracy: 0.00001)
        XCTAssertEqual(validKey.latitude, 0, accuracy: 0.00001)
    }
    
}
