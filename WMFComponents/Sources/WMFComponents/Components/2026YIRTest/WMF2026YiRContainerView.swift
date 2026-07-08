import SwiftUI

// MARK: - Container

/// Root view. Handles tap-left/tap-right (story-style) + swipe-up (Explore-style) navigation.
public struct WMFYiR2026ContainerView: View {

    @ObservedObject var viewModel: WMFYiR2026ViewModel
    let onDismiss: () -> Void

    // Swipe-up drag state
    @State private var dragOffsetY: CGFloat = 0
    @State private var isDragging = false

    public init(viewModel: WMFYiR2026ViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // MARK: Slide content
                slideContent(geo: geo)

                // MARK: Story progress bar
                WMFYiR2026ProgressBar(
                    totalSegments: viewModel.slides.count,
                    currentIndex: viewModel.currentIndex,
                    completedSegmentFills: viewModel.segmentProgress,
                    activeSegmentFill: viewModel.activeSegmentFill
                )
                .padding(.horizontal, 12)
                .padding(.top, geo.safeAreaInsets.top + 8)

                // MARK: Dismiss button
                dismissButton
                    .padding(.top, geo.safeAreaInsets.top + 36)
                    .padding(.trailing, 16)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                // MARK: Tap zones (always present)
                // On interactive slides restrict height to top 55% so the card
                // buttons underneath can still receive touches.
                tapZones(geo: geo)
            }
            .offset(y: dragOffsetY)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: dragOffsetY)
            .gesture(swipeUpGesture(geo: geo))
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }

    // MARK: Slide content

    @ViewBuilder
    private func slideContent(geo: GeometryProxy) -> some View {
        let slide = viewModel.slides[viewModel.currentIndex]
        Group {
            switch slide.content {
            case .content(let data):
                WMFYiR2026ContentSlideView(data: data)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            case .interactive(let data):
                WMFYiR2026InteractiveSlideView(
                    data: data,
                    selectedOptionIndex: viewModel.selections[data.id]
                ) { optionIndex in
                    viewModel.selectOption(slideID: data.id, optionIndex: optionIndex)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .id(viewModel.currentIndex) // forces SwiftUI to re-create for transition
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
        .frame(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
    }

    // MARK: Tap zones

    private func tapZones(geo: GeometryProxy) -> some View {
        // On interactive slides restrict to top 50% so card buttons stay tappable
        let isInteractive: Bool = {
            if case .interactive = viewModel.slides[viewModel.currentIndex].content { return true }
            return false
        }()
        let height = isInteractive ? geo.size.height * 0.50 : geo.size.height

        return HStack(spacing: 0) {
            // Retreat: left 35%
            Color.clear
                .contentShape(Rectangle())
                .frame(width: geo.size.width * 0.35)
                .onTapGesture { viewModel.retreat() }

            // Advance: right 65%
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity)
                .onTapGesture { viewModel.advance() }
        }
        .frame(height: height, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        // Keep tap zones below the progress bar + dismiss button
        .padding(.top, 80)
    }

    // MARK: Swipe-up gesture (Explore "for you" style)

    private func swipeUpGesture(geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Only track upward drags
                if value.translation.height < 0 {
                    dragOffsetY = value.translation.height * 0.4
                    isDragging = true
                }
            }
            .onEnded { value in
                isDragging = false
                dragOffsetY = 0
                let velocity = value.predictedEndTranslation.height
                if value.translation.height < -80 || velocity < -300 {
                    viewModel.advance()
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

// MARK: - Story Progress Bar

struct WMFYiR2026ProgressBar: View {

    let totalSegments: Int
    let currentIndex: Int
    let completedSegmentFills: [CGFloat]
    let activeSegmentFill: CGFloat

    private let segmentHeight: CGFloat = 3
    private let spacing: CGFloat = 4

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSegments, id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * fillForSegment(index))
                    }
                }
                .frame(height: segmentHeight)
            }
        }
    }

    private func fillForSegment(_ index: Int) -> CGFloat {
        if index < currentIndex {
            return completedSegmentFills[index]  // 1.0 for passed, 0 if rewound
        } else if index == currentIndex {
            return activeSegmentFill
        } else {
            return 0
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
