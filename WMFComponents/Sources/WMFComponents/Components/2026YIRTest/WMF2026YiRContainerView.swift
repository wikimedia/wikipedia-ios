import SwiftUI

// MARK: - Container

/// Root view. Swipe up to advance, swipe down to retreat.
public struct WMFYiR2026ContainerView: View {

    @ObservedObject var viewModel: WMFYiR2026ViewModel
    let onDismiss: () -> Void

    @State private var dragOffsetY: CGFloat = 0

    public init(viewModel: WMFYiR2026ViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // MARK: Slide content
                slideContent(geo: geo)

                // MARK: Dismiss button
                dismissButton
                    .padding(.top, geo.safeAreaInsets.top + 36)
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .offset(y: dragOffsetY)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragOffsetY)
            .gesture(swipeGesture(geo: geo))
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }

    // MARK: Slide content

    @ViewBuilder
    private func slideContent(geo: GeometryProxy) -> some View {
        let slide = viewModel.slides[viewModel.currentIndex]
        let insertEdge: Edge = viewModel.isRetreating ? .top : .bottom
        let removeEdge: Edge = viewModel.isRetreating ? .bottom : .top

        Group {
            switch slide.content {
            case .content(let data):
                WMFYiR2026ContentSlideView(data: data)
                    .transition(.asymmetric(
                        insertion: .move(edge: insertEdge),
                        removal: .move(edge: removeEdge)
                    ))
            case .interactive(let data):
                WMFYiR2026InteractiveSlideView(
                    data: data,
                    selectedOptionIndex: viewModel.selections[data.id]
                ) { optionIndex in
                    viewModel.selectOption(slideID: data.id, optionIndex: optionIndex)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: insertEdge),
                    removal: .move(edge: removeEdge)
                ))
            case .imageQuiz(let data):
                WMFYiR2026ImageQuizSlideView(
                    data: data,
                    selectedOptionIndex: viewModel.selections[data.id]
                ) { optionIndex in
                    viewModel.selectOption(slideID: data.id, optionIndex: optionIndex)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: insertEdge),
                    removal: .move(edge: removeEdge)
                ))
            }
        }
        .id(viewModel.currentIndex)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.currentIndex)
        .frame(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
    }

    // MARK: Swipe up/down gesture

    private func swipeGesture(geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Only rubber-band in the direction that makes sense
                let isInteractive: Bool
                if case .interactive = viewModel.slides[viewModel.currentIndex].content {
                    isInteractive = true
                } else {
                    isInteractive = false
                }
                // On interactive slides don't rubber-band upward so the card
                // scroll/tap still feels natural
                if isInteractive && value.translation.height < 0 { return }
                dragOffsetY = value.translation.height * 0.3
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height
                dragOffsetY = 0

                if value.translation.height < -60 || velocity < -400 {
                    // Swiped up → advance
                    viewModel.advance()
                } else if value.translation.height > 60 || velocity > 400 {
                    // Swiped down → retreat
                    viewModel.retreat()
                }
            }
    }

    // MARK: Dismiss

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WMFYiR2026ContainerView(
        viewModel: WMFYiR2026ViewModel(),
        onDismiss: {}
    )
}
#endif
