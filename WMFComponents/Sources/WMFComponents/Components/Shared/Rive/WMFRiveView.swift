import SwiftUI
import RiveRuntime

public struct WMFRiveView: View {

    @StateObject private var viewModel: WMFRiveAnimationViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityPlayAnimatedImages) private var playAnimatedImages
    @Environment(\.layoutDirection) private var environmentLayoutDirection

    private let text: [WMFRiveText: String]
    private let numbers: [WMFRiveNumber: Double]
    private let bools: [WMFRiveBool: Bool]
    private let images: [WMFRiveImage: Data]
    private let layoutDirection: WMFRiveLayoutDirection?
    private let accessibilityLabel: String?
    private let frameRate: Int?
    /// `false` keeps the animation on its first frame. A pager sets it only on the current page, so
    /// a page that is built off-screen does not play its intro before the reader sees it.
    private let isPlaying: Bool
    /// `true` plays the animation also when Reduce Motion is on, for a small loading animation
    /// that has no end state.
    private let playsWithReduceMotion: Bool
    private let onReadBool: (@MainActor (Bool) -> Void)?
    private let onWatchedEvent: (@MainActor () -> Void)?

    public init(
        _ animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        bools: [WMFRiveBool: Bool] = [:],
        images: [WMFRiveImage: Data] = [:],
        layoutDirection: WMFRiveLayoutDirection? = nil,
        accessibilityLabel: String? = nil,
        frameRate: Int? = nil,
        isPlaying: Bool = true,
        playsWithReduceMotion: Bool = false,
        readBool: WMFRiveBool? = nil,
        onReadBool: (@MainActor (Bool) -> Void)? = nil,
        watchedTrigger: WMFRiveTrigger? = nil,
        missingImageFlags: [WMFRiveImage: WMFRiveBool] = [:],
        onWatchedEvent: (@MainActor () -> Void)? = nil
    ) {
        self.text = text
        self.numbers = numbers
        self.bools = bools
        self.images = images
        self.layoutDirection = layoutDirection
        self.accessibilityLabel = accessibilityLabel
        self.frameRate = frameRate
        self.isPlaying = isPlaying
        self.playsWithReduceMotion = playsWithReduceMotion
        self.onReadBool = onReadBool
        self.onWatchedEvent = onWatchedEvent
        _viewModel = StateObject(wrappedValue: WMFRiveAnimationViewModel(
            animation: animation,
            text: text,
            numbers: numbers,
            bools: bools,
            images: images,
            readBool: readBool,
            watchedTrigger: watchedTrigger,
            missingImageFlags: missingImageFlags
        ))
    }

    public var body: some View {
        content
            .onAppear {
                // Before the load, so the first frame already has the layout direction.
                viewModel.update(enums: enums)
                viewModel.update(showsSettledState: showsSettledState)
                viewModel.loadIfNeeded()
            }
            .onChange(of: showsSettledState) {
                viewModel.update(showsSettledState: showsSettledState)
            }
            .onChange(of: environmentLayoutDirection) {
                viewModel.update(enums: enums)
            }
            .onDisappear {
                viewModel.unload()
            }
            .onChange(of: isPlaying) { wasPlaying, isPlaying in
                // A pager keeps some pages that are not current. Start such a page again while it
                // is off-screen, so it plays from its first frame each time the reader comes back.
                if wasPlaying && !isPlaying {
                    viewModel.restart()
                }
            }
            .onChange(of: text) {
                viewModel.update(text: text, numbers: numbers)
            }
            .onChange(of: numbers) {
                viewModel.update(text: text, numbers: numbers)
            }
            .onChange(of: bools) {
                viewModel.update(bools: bools)
            }
            .onChange(of: images) {
                viewModel.update(images: images)
            }
            .onChange(of: viewModel.watchedEventCount) {
                onWatchedEvent?()
            }
            .onChange(of: viewModel.readBoolValue) {
                if let value = viewModel.readBoolValue {
                    onReadBool?(value)
                }
            }
    }

    /// Not a pause: a paused view does not draw the images that arrive after the load, or the
    /// changes after a tap.
    private var showsSettledState: Bool {
        !playsWithReduceMotion && (reduceMotion || !playAnimatedImages)
    }

    private var enums: [WMFRiveEnum: String] {
        guard let layoutDirection else { return [:] }
        return [layoutDirection.property: layoutDirection.value(for: environmentLayoutDirection)]
    }

    @ViewBuilder
    private var content: some View {
        if let accessibilityLabel {
            animationLayer
                .accessibilityElement()
                .accessibilityAddTraits(.isImage)
                .accessibilityLabel(accessibilityLabel)
        } else {
            animationLayer
                .accessibilityHidden(true)
        }
    }

    private var animationLayer: some View {
        representable
            .opacity(viewModel.loadState.isLoaded ? 1 : 0)
    }

    private var representable: RiveUIViewRepresentable {
        var representable = RiveUIViewRepresentable(rive: viewModel.rive)
            .paused(!isPlaying)

        if let frameRate {
            representable = representable.frameRate(.fps(frameRate))
        }

        return representable
    }
}
