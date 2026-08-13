import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFSettingsDataControllerEditModeTests {

    private let fixture = WMFDataTestFixture()

    @Test
    func defaultEditModeIsNilInitially() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(WMFSettingsDataController.shared.defaultEditMode() == nil)
        }
    }

    @Test
    func setAndLoadDefaultEditMode() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFSettingsDataController.shared.setDefaultEditMode(.visual)
            #expect(WMFSettingsDataController.shared.defaultEditMode() == .visual)

            WMFSettingsDataController.shared.setDefaultEditMode(.source)
            #expect(WMFSettingsDataController.shared.defaultEditMode() == .source)
        }
    }

    @Test
    func clearDefaultEditMode() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFSettingsDataController.shared.setDefaultEditMode(.visual)
            WMFSettingsDataController.shared.clearDefaultEditMode()
            #expect(WMFSettingsDataController.shared.defaultEditMode() == nil)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }
}
