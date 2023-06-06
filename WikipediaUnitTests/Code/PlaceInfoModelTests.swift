import XCTest
@testable import Wikipedia

class PlaceInfoModelTests: XCTestCase {
    
    func testPlaceInfoModelWithNoParameters() {
        // Given
        let ditionary: [String: Any] = [:]
        // When
        let sut = PlaceInfoModel(ditionary)
        // Then
        XCTAssertNil(sut)
        
        // When
        let sut2 = PlaceInfoModel(nil)
        // Then
        XCTAssertNil(sut2)
    }
    
    func testPlaceInfoModelWithOtherParameters() {
        // Given
        let ditionary: [String: Any] = ["lat": 0, "long": 0]
        // When
        let sut = PlaceInfoModel(ditionary)
        // Then
        XCTAssertNil(sut)
    }
    
    func testPlaceInfoModelWithNeededParameters() {
        // Given
        let ditionary: [String: Any] = ["placeInfo" : ["latitude": 51.2,
                                                       "longitude": "12.3"]]
        // When
        let sut = PlaceInfoModel(ditionary)
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut?.latitude, 51.2)
        XCTAssertEqual(sut?.longitude, 12.3)
    }
}
