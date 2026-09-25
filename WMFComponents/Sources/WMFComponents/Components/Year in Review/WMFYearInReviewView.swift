import SwiftUI

public struct WMFYearInReviewView: View {

    @ObservedObject var viewModel: WMFYearInReviewViewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        pager
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(
                        bottomLeading: WMFYearInReviewViewModel.slideCornerRadius,
                        bottomTrailing: WMFYearInReviewViewModel.slideCornerRadius
                    )
                )
            )
            .overlay(alignment: .topTrailing) {
                WMFYearInReviewProgressView(
                    slideCount: viewModel.slides.count,
                    currentIndex: viewModel.currentSlideIndex,
                    color: Color(uiColor: viewModel.currentSlide?.contentColor ?? WMFColor.white)
                )
                .padding(.trailing, WMFYearInReviewViewModel.progressBarEdgeInset)
                .padding(.top, viewModel.progressBarTopInset)
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(uiColor: WMFYearInReviewViewModel.chromeBackgroundColor))
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentSlideID)
            .onAppear {
                viewModel.onAppear()
            }
    }

    /// Each branch is a whole ScrollView. A conditional placed between the ScrollView and the
    /// layout marked `.scrollTargetLayout()` stops the paging from resolving.
    ///
    /// A lazy stack only builds the visible row and its neighbour, and VoiceOver can only reach
    /// a view that exists, so it escapes the flow part way through. Every slide is built while
    /// VoiceOver runs; otherwise the stack stays lazy, which matters because each slide holds a
    /// Metal-backed Rive view.
    @ViewBuilder
    private var pager: some View {
        if voiceOverEnabled {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    slideViews
                }
                .scrollTargetLayout()
            }
            .modifier(
                WMFYearInReviewPagingModifier(
                    currentSlideID: $viewModel.currentSlideID,
                    positionAccessibilityValue: viewModel.slidePositionAccessibilityValue
                )
            )
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    slideViews
                }
                .scrollTargetLayout()
            }
            .modifier(
                WMFYearInReviewPagingModifier(
                    currentSlideID: $viewModel.currentSlideID,
                    positionAccessibilityValue: viewModel.slidePositionAccessibilityValue
                )
            )
        }
    }

    /// `ForEach` iterates the slides directly. Wrapping them in `enumerated()` makes the element
    /// a tuple, identity cannot resolve, and `.scrollPosition(id:)` silently stops updating.
    @ViewBuilder
    private var slideViews: some View {
        ForEach(viewModel.slides) { slide in
            WMFYearInReviewSlideView(slide: slide)
                .containerRelativeFrame(.vertical)
                .id(slide.id)
        }
    }
}

private struct WMFYearInReviewPagingModifier: ViewModifier {

    @Binding var currentSlideID: String?

    /// Carries the position to VoiceOver, which cannot read it off the progress bar.
    let positionAccessibilityValue: String

    @ViewBuilder
    func body(content: Content) -> some View {
        let paged = content
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentSlideID)
            .scrollIndicators(.hidden)
            .accessibilityElement(children: .contain)
            .accessibilityValue(positionAccessibilityValue)

        if #available(iOS 26.0, *) {
            paged.scrollEdgeEffectHidden(true, for: .all)
        } else {
            paged
        }
    }
}
