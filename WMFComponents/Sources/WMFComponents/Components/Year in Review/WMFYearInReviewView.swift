import SwiftUI

public struct WMFYearInReviewView: View {

    @ObservedObject var viewModel: WMFYearInReviewViewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var donateButtonFrame: CGRect = .zero

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            pager
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(
                            bottomLeading: WMFYearInReviewViewModel.slideCornerRadius,
                            bottomTrailing: WMFYearInReviewViewModel.slideCornerRadius
                        )
                    )
                )

            WMFYearInReviewToolbarView(
                viewModel: viewModel,
                contentColor: Color(uiColor: WMFColor.white),
                donateSourceRect: { donateButtonFrame }
            )
            .frame(minHeight: WMFYearInReviewViewModel.toolbarMinimumHeight)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { donateButtonFrame = proxy.frame(in: .global) }
                        .onChange(of: proxy.frame(in: .global)) { donateButtonFrame = $1 }
                }
            }
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
            .modifier(WMFYearInReviewPagingModifier(currentSlideID: $viewModel.currentSlideID))
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    slideViews
                }
                .scrollTargetLayout()
            }
            .modifier(WMFYearInReviewPagingModifier(currentSlideID: $viewModel.currentSlideID))
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

    @ViewBuilder
    func body(content: Content) -> some View {
        let paged = content
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentSlideID)
            .scrollIndicators(.hidden)
            .accessibilityElement(children: .contain)

        if #available(iOS 26.0, *) {
            paged.scrollEdgeEffectHidden(true, for: .all)
        } else {
            paged
        }
    }
}
