import SwiftUI
import RiveRuntime

public struct WMFRiveView: View {

    @StateObject private var viewModel: WMFRiveAnimationViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityPlayAnimatedImages) private var playAnimatedImages

    private let text: [WMFRiveText: String]
    private let numbers: [WMFRiveNumber: Double]
    private let accessibilityLabel: String?
    private let frameRate: Int?

    public init(
        _ animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        accessibilityLabel: String? = nil,
        frameRate: Int? = nil
    ) {
        self.text = text
        self.numbers = numbers
        self.accessibilityLabel = accessibilityLabel
        self.frameRate = frameRate
        _viewModel = StateObject(wrappedValue: WMFRiveAnimationViewModel(
            animation: animation,
            text: text,
            numbers: numbers
        ))
    }

    public var body: some View {
        content
            .onAppear {
                viewModel.loadIfNeeded()
            }
            .onDisappear {
                viewModel.unload()
            }
            .onChange(of: text) {
                viewModel.update(text: text, numbers: numbers)
            }
            .onChange(of: numbers) {
                viewModel.update(text: text, numbers: numbers)
            }
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
            .paused(reduceMotion || !playAnimatedImages)

        if let frameRate {
            representable = representable.frameRate(.fps(frameRate))
        }

        return representable
    }
}
