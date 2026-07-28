import XCTest
@testable import WMFData
import WMFDataMocks

final class WMFSettingsDataControllerEditModeTests: XCTestCase {

    override func setUp() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }

    func testDefaultEditModeIsNilInitially() {
        XCTAssertNil(WMFSettingsDataController.shared.defaultEditMode())
    }

    func testSetAndLoadDefaultEditMode() {
        WMFSettingsDataController.shared.setDefaultEditMode(.visual)
        XCTAssertEqual(WMFSettingsDataController.shared.defaultEditMode(), .visual)

        WMFSettingsDataController.shared.setDefaultEditMode(.source)
        XCTAssertEqual(WMFSettingsDataController.shared.defaultEditMode(), .source)
    }

    func testClearDefaultEditMode() {
        WMFSettingsDataController.shared.setDefaultEditMode(.visual)
        WMFSettingsDataController.shared.clearDefaultEditMode()
        XCTAssertNil(WMFSettingsDataController.shared.defaultEditMode())
    }
}
