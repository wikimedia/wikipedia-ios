import Testing
import Foundation
import RiveRuntime
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
            loader: { animation, _ in
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

    /// A load that fails must release its task handle. Before this was fixed, `loadIfNeeded`
    /// saw a non-nil handle and returned early for the rest of the view model's life, so a
    /// slide that lost the race to build the Metal worker stayed blank even though
    /// `WMFRiveWorkerProvider.sharedWorker()` would have built one on the next attempt.
    @Test
    func aFailedLoadDoesNotBlockTheNextAttempt() async {
        var attempts = 0
        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            loader: { _, _ in
                attempts += 1
                throw StubError.cannotLoad
            }
        )

        await viewModel.loadIfNeeded()?.value
        #expect(attempts == 1)

        let retry = viewModel.loadIfNeeded()
        #expect(retry != nil, "a failed load must not block the next attempt")
        await retry?.value
        #expect(attempts == 2)
    }

    /// The opposite guard: a load already in flight must not be started twice.
    @Test
    func aLoadInFlightIsNotStartedTwice() async {
        var attempts = 0
        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            loader: { _, _ in
                attempts += 1
                try? await Task.sleep(nanoseconds: 50_000_000)
                throw StubError.cannotLoad
            }
        )

        let inFlight = viewModel.loadIfNeeded()
        #expect(viewModel.loadIfNeeded() == nil, "a load in flight must not start another")
        #expect(viewModel.loadIfNeeded() == nil)

        await inFlight?.value
        #expect(attempts == 1, "three calls while one load is in flight must start one load")
    }

    /// The templates name the cases of their layout direction enum "Left to Right" and "Right to Left".
    @Test
    func theLayoutDirectionPicksTheEnumCaseForTheDirection() {
        let layoutDirection = WMFRiveLayoutDirection(property: WMFRiveEnum(path: "layoutDir"))
        #expect(layoutDirection.value(for: .leftToRight) == "Left to Right")
        #expect(layoutDirection.value(for: .rightToLeft) == "Right to Left")
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

    /// A script in the .riv gets its view models when the state machine is made, and it does not see
    /// an instance that is bound after that (T441488). So the text and the fitted size must be on the
    /// instances that the state machine binds when it is made.
    /// The templates set the maximum line counts on the instance that has the name of the artboard.
    /// The default instance has zeros, which keeps the copy to one line.
    @Test
    func theStateMachineBindsTheInstanceThatHasTheNameOfTheArtboard() async throws {
        let data = WMFRiveText(path: "data")
        let longNumber = "1,234,567,890"

        var boundData: String?
        var boundMaxLines: Float?
        let viewModel = WMFRiveAnimationViewModel(
            animation: WMFRiveAnimation(resourceName: "all_templates", artboardName: "frame1", stateMachineName: "frame1-statemachine"),
            text: [data: longNumber],
            loader: { animation, bindings in
                try await WMFRiveWorkerProvider.makeRive(for: animation) { file, artboard in
                    let main = await bindings(file, artboard)
                    boundData = try? await main?.value(of: StringProperty(path: data.path))
                    boundMaxLines = try? await main?.value(of: NumberProperty(path: "headlineMaxlines"))
                    return main
                }
            }
        )

        await viewModel.load()

        #expect(viewModel.loadState.isLoaded)
        #expect(boundData == longNumber)
        #expect(try #require(boundMaxLines) > 1)
    }

    @Test
    func aRestartBeforeTheLoadDoesNothing() async {
        var attempts = 0
        let viewModel = WMFRiveAnimationViewModel(
            animation: animation,
            loader: { _, _ in
                attempts += 1
                throw StubError.cannotLoad
            }
        )

        #expect(viewModel.restart() == nil)
        #expect(attempts == 0)
    }

    /// A pager restarts a page that it keeps off-screen, so the page plays again when it comes back.
    /// The restart makes a new animation and keeps the page loaded, so the page does not go blank.
    @Test
    func aRestartMakesANewAnimationAndStaysLoaded() async throws {
        let viewModel = WMFRiveAnimationViewModel(
            animation: WMFRiveAnimation(resourceName: "all_templates", artboardName: "frame1", stateMachineName: "frame1-statemachine"),
            text: [WMFRiveText(path: "data"): "42"]
        )
        await viewModel.load()
        let first = try #require(viewModel.rive)

        let restart = viewModel.restart()
        #expect(viewModel.loadState.isLoaded, "the current animation stays during the restart")
        await restart?.value

        let second = try #require(viewModel.rive)
        #expect(second !== first)
        #expect(viewModel.loadState.isLoaded)
    }

    @Test
    func theTemplatesAnimationIsInTheBundle() {
        let templates = WMFRiveAnimation(resourceName: "all_templates")
        #expect(WMFRiveWorkerProvider.resourceExists(for: templates))
    }
}
