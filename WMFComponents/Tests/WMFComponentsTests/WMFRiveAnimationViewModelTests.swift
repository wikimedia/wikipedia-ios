import Testing
import Foundation
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

    /// `loadIfNeeded` starts a task and returns, so a test has to wait for the work to land.
    /// Every wait here is on the failure handler, which the load calls last, so everything
    /// before it in the catch has already run.
    private func waitFor(
        _ description: String,
        timeout: TimeInterval = 5,
        until condition: @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        if !condition() {
            Issue.record("timed out waiting for \(description)")
        }
    }

    /// A load that fails must release its task handle. Before this was fixed, `loadIfNeeded`
    /// saw a non-nil handle and returned early for the rest of the view model's life, so a
    /// slide that lost the race to build the Metal worker stayed blank even though
    /// `WMFRiveWorkerProvider.sharedWorker()` would have built one on the next attempt.
    @Test
    func aFailedLoadDoesNotBlockTheNextAttempt() async {
        var attempts = 0
        var failures = 0
        WMFRiveLogger.failureHandler = { _ in failures += 1 }
        defer { WMFRiveLogger.failureHandler = nil }

        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            loader: { _ in
                attempts += 1
                throw StubError.cannotLoad
            }
        )

        viewModel.loadIfNeeded()
        await waitFor("the first load to fail") { failures == 1 }
        #expect(attempts == 1)

        viewModel.loadIfNeeded()
        await waitFor("the second load to run") { failures == 2 }
        #expect(attempts == 2, "a failed load must not block the next attempt")
    }

    /// The opposite guard: a load already in flight must not be started twice.
    @Test
    func aLoadInFlightIsNotStartedTwice() async {
        var attempts = 0
        var failures = 0
        WMFRiveLogger.failureHandler = { _ in failures += 1 }
        defer { WMFRiveLogger.failureHandler = nil }

        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            loader: { _ in
                attempts += 1
                try? await Task.sleep(nanoseconds: 50_000_000)
                throw StubError.cannotLoad
            }
        )

        viewModel.loadIfNeeded()
        viewModel.loadIfNeeded()
        viewModel.loadIfNeeded()

        await waitFor("the load to finish") { failures == 1 }
        #expect(attempts == 1, "three calls while one load is in flight must start one load")
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
