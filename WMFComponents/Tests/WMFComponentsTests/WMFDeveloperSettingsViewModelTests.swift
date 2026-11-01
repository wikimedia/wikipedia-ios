import Testing
import Foundation
@testable import WMFComponents

@MainActor
@Suite
struct WMFDeveloperSettingsViewModelTests {

    private enum StubError: Error {
        case cannotBuild
    }

    private func makeViewModel(regenerate: (@MainActor () async throws -> Bool)?) -> WMFDeveloperSettingsViewModel {
        let strings = WMFDeveloperSettingsLocalizedStrings(developerSettings: "", doNotPostImageRecommendations: "", sendAnalyticsToWMFLabs: "", bypassDonation: "", forceEmailAuth: "", done: "")
        let viewModel = WMFDeveloperSettingsViewModel(localizedStrings: strings)
        viewModel.regenerateYiR2026Report = regenerate
        return viewModel
    }

    @Test
    func regenerateShowsTheSpinnerUntilTheReportIsBuilt() async {
        let viewModel = makeViewModel { true }

        let task = viewModel.tappedRegenerateYiR2026Report()
        #expect(viewModel.isRegeneratingYiR2026Report)

        await task?.value
        #expect(!viewModel.isRegeneratingYiR2026Report)
        #expect(viewModel.yiR2026ReportAlertMessage?.contains("was built again") == true)
    }

    @Test
    func regenerateReportsAReportThatWasNotBuilt() async {
        let viewModel = makeViewModel { false }

        await viewModel.tappedRegenerateYiR2026Report()?.value

        #expect(viewModel.yiR2026ReportAlertMessage?.contains("was not built") == true)
    }

    @Test
    func regenerateReportsAnError() async {
        let viewModel = makeViewModel { throw StubError.cannotBuild }

        await viewModel.tappedRegenerateYiR2026Report()?.value

        #expect(!viewModel.isRegeneratingYiR2026Report)
        #expect(viewModel.yiR2026ReportAlertMessage?.contains("was not built") == true)
    }

    @Test
    func regenerateDoesNothingWithoutTheAppAction() {
        let viewModel = makeViewModel(regenerate: nil)

        #expect(viewModel.tappedRegenerateYiR2026Report() == nil)
        #expect(!viewModel.isRegeneratingYiR2026Report)
        #expect(viewModel.yiR2026ReportAlertMessage == nil)
    }
}
