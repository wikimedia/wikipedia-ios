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
                        // The radius does not change on the end screen. If it changed, the corners of
                        // the last slide could change during the swipe. On the end screen, the color
                        // behind the corners is the page color, thus the corners do not show.
                        bottomLeading: WMFYearInReviewViewModel.slideCornerRadius,
                        bottomTrailing: WMFYearInReviewViewModel.slideCornerRadius
                    )
                )
            )
            .overlay(alignment: .topTrailing) {
                WMFYearInReviewProgressView(
                    slideCount: viewModel.pageCount,
                    currentIndex: viewModel.currentPageIndex,
                    color: Color(uiColor: viewModel.currentContentColor ?? WMFColor.white)
                )
                .padding(.trailing, WMFYearInReviewViewModel.progressBarEdgeInset)
                .padding(.top, viewModel.progressBarTopInset)
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(uiColor: viewModel.currentChromeColor))
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
                    endPage
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
                    endPage
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

    /// The end screen, one page after the last slide. It scrolls on its own inside its page.
    @ViewBuilder
    private var endPage: some View {
        if let endViewModel = viewModel.endViewModel {
            WMFYearInReviewEndView(
                viewModel: endViewModel,
                topInset: viewModel.topSafeAreaInset,
                onUsesLightContentChange: { usesLightContent in
                    if viewModel.endUsesLightContent != usesLightContent {
                        viewModel.endUsesLightContent = usesLightContent
                    }
                }
            )
                .containerRelativeFrame(.vertical)
                .id(WMFYearInReviewViewModel.endPageID)
        }
    }

    /// `ForEach` iterates the slides directly. Wrapping them in `enumerated()` makes the element
    /// a tuple, identity cannot resolve, and `.scrollPosition(id:)` silently stops updating.
    @ViewBuilder
    private var slideViews: some View {
        ForEach(viewModel.slides) { slide in
            WMFYearInReviewSlideView(
                slide: slide,
                isCurrent: slide.id == viewModel.currentSlideID,
                onLightContentFlag: { lightContent in
                    viewModel.slideDidLoad(lightContent: lightContent, slideID: slide.id)
                },
                donateButtonTitle: viewModel.localizedStrings.donateButtonTitle,
                isLoadingDonate: viewModel.isLoadingDonate,
                onTapDonate: { sourceRect in
                    viewModel.tappedDonate(sourceRect: sourceRect)
                }
            )
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
            .scrollTargetBehavior(.viewAligned(limitBehavior: pageLimit))
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

    /// The scroll view stops at the top of each page view. It does not use the height of the
    /// scroll view, because that height includes the bottom inset below the toolbar.
    /// Thus, the stop position stays correct on each page and the error does not increase.
    /// One swipe moves a maximum of one page.
    private var pageLimit: ViewAlignedScrollTargetBehavior.LimitBehavior {
        if #available(iOS 18.0, *) {
            return .alwaysByOne
        }
        return .always
    }
}
