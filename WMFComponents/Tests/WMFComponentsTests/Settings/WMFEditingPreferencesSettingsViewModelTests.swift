import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
@MainActor
final class WMFEditingPreferencesSettingsViewModelTests {

    private let fixture = WMFDataTestFixture()

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }

    @Test
    func initialSelectionDefaultsToVisual() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFEditingPreferencesSettingsViewModel()
            #expect(viewModel.selectedMode == .visual)
        }
    }

    @Test
    func initialSelectionReflectsStoredMode() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFSettingsDataController.shared.setDefaultEditMode(.source)

            let viewModel = WMFEditingPreferencesSettingsViewModel()
            #expect(viewModel.selectedMode == .source)
        }
    }

    @Test
    func selectingPersistsTheMode() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFEditingPreferencesSettingsViewModel()
            viewModel.select(.source)

            #expect(viewModel.selectedMode == .source)
            #expect(WMFSettingsDataController.shared.defaultEditMode() == .source)
        }
    }

    /// Changing the mode here must not suppress the choose editor sheet — only the sheet's own
    /// "Don't show this again" checkbox does that.
    @Test
    func selectingDoesNotSuppressChooseEditorSheet() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFEditingPreferencesSettingsViewModel()
            viewModel.select(.source)

            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == false)
        }
    }

    @Test
    func selectingTheAlreadySelectedModeIsANoop() async throws {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFEditingPreferencesSettingsViewModel()
            #expect(viewModel.selectedMode == .visual)

            viewModel.select(.visual)
            #expect(viewModel.selectedMode == .visual)
            #expect(WMFSettingsDataController.shared.skipChooseEditorSheet() == false)
        }
    }
}
