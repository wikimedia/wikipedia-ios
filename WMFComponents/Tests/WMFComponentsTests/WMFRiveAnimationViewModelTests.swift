import Testing
@testable import WMFComponents

@MainActor
@Suite
struct WMFRiveAnimationViewModelTests {

    private enum StubError: Error {
        case cannotLoad
    }

    private let animation = WMFRiveAnimation(resourceName: "does-not-exist", artboardName: "main")

    private func makeViewModel(
        text: [WMFRiveText: String] = [:],
        loader: @escaping @MainActor (WMFRiveAnimation) async throws -> Void = { _ in throw StubError.cannotLoad }
    ) -> WMFRiveAnimationViewModel {
        return WMFRiveAnimationViewModel(
            animation: animation,
            text: text,
            loader: { animation in
                try await loader(animation)
                throw StubError.cannotLoad
            }
        )
    }

    @Test
    func startsIdle() {
        #expect(makeViewModel().loadState.isLoaded == false)
    }

    @Test
    func failedLoadReportsFailureAndKeepsNoAnimation() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        #expect(viewModel.loadState.isLoaded == false)
        #expect(viewModel.rive == nil)
        if case .failed = viewModel.loadState {} else {
            Issue.record("expected the load state to be failed")
        }
    }

    @Test
    func failureReachesTheHandlerForAnalytics() async {
        var reported: [WMFRiveFailure] = []
        WMFRiveLogger.failureHandler = { reported.append($0) }
        defer { WMFRiveLogger.failureHandler = nil }

        await makeViewModel().load()

        #expect(reported.count == 1)
        #expect(reported.first?.animation.resourceName == "does-not-exist")
        #expect(reported.first?.animation.artboardName == "main")
    }

    @Test
    func unloadReturnsToIdle() async {
        let viewModel = makeViewModel()

        await viewModel.load()
        viewModel.unload()

        #expect(viewModel.rive == nil)
        #expect(viewModel.loadState.isLoaded == false)
    }

    @Test
    func theAnimationCarriesItsArtboard() {
        let loading = WMFRiveAnimation(resourceName: "onboarding-loading", artboardName: "loading")
        #expect(loading.resourceName == "onboarding-loading")
        #expect(loading.artboardName == "loading")
        #expect(loading.stateMachineName == nil)
    }

    @Test
    func aMissingResourceIsReportedBeforeAnyLoad() {
        #expect(WMFRiveWorkerProvider.resourceExists(for: animation) == false)
    }

    @Test
    func theSampleAnimationIsInTheBundle() {
        let sample = WMFRiveAnimation(resourceName: "autolayout_multiple_instances_test")
        #expect(WMFRiveWorkerProvider.resourceExists(for: sample))
    }
}
