import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFSettingsDataControllerEditModeTests {

    private let fixture = WMFDataTestFixture()

    @Test
    func defaultEditModeIsVisualInitially() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(WMFSettingsDataController.shared.defaultEditMode() == .visual)
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
    func skipChooseEditorSheetIsFalseInitially() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == false)
        }
    }

    @Test
    func setAndLoadSkipChooseEditorSheet() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFSettingsDataController.shared.setSkipChooseEditorSheet(true)
            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == true)

            WMFSettingsDataController.shared.setSkipChooseEditorSheet(false)
            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == false)
        }
    }

    /// The editing preferences screen writes the mode without ever suppressing the sheet — only the
    /// sheet's own checkbox does that.
    @Test
    func settingModeDoesNotSuppressSheet() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFSettingsDataController.shared.setDefaultEditMode(.source)
            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == false)
        }
    }

    @Test
    func clearDefaultEditModeResetsBothPreferences() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFSettingsDataController.shared.setDefaultEditMode(.source)
            WMFSettingsDataController.shared.setSkipChooseEditorSheet(true)

            WMFSettingsDataController.shared.clearDefaultEditMode()

            #expect(WMFSettingsDataController.shared.defaultEditMode() == .visual)
            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == false)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }
}
