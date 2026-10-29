import SwiftUI
import UIKit

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
                viewModel.showsAnswersAsSlides = voiceOverEnabled
                viewModel.onAppear()
            }
            .onChange(of: voiceOverEnabled) {
                viewModel.showsAnswersAsSlides = voiceOverEnabled
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
                .background {
                    WMFYearInReviewPageObserver(slideIDs: viewModel.pageIDs) { slideID in
                        viewModel.currentSlideID = slideID
                    }
                }
            }
            .modifier(
                WMFYearInReviewPagingModifier(
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
                .background {
                    WMFYearInReviewPageObserver(slideIDs: viewModel.pageIDs) { slideID in
                        viewModel.currentSlideID = slideID
                    }
                }
            }
            .modifier(
                WMFYearInReviewPagingModifier(
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

    /// `ForEach` iterates the slides directly, so that each slide keeps its identity.
    @ViewBuilder
    private var slideViews: some View {
        ForEach(viewModel.pagerSlides) { slide in
            WMFYearInReviewSlideView(
                slide: slide,
                isCurrent: slide.id == viewModel.currentSlideID,
                onLightContentFlag: { lightContent in
                    viewModel.slideDidLoad(lightContent: lightContent, slideID: slide.id)
                },
                showsAnswerInPlace: !voiceOverEnabled,
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

/// Sets the current slide when the pager rests on a page: after a swipe, a VoiceOver scroll or a
/// move from code. It reads the `UIScrollView`, not `.scrollPosition(id:)`. That binding does not
/// see a scroll from code, and a change of the binding from code stops about a third of a slide past
/// the slide (the scroll view has a bottom content inset under the toolbar; seen on iOS 26.5).
private struct WMFYearInReviewPageObserver: UIViewRepresentable {

    let slideIDs: [String]
    let onPageChange: @MainActor (String) -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        uiView.slideIDs = slideIDs
        uiView.onPageChange = onPageChange
    }

    final class ObserverView: UIView {
        var slideIDs: [String] = []
        var onPageChange: (@MainActor (String) -> Void)?
        private var observation: NSKeyValueObservation?
        private var sizeObservation: NSKeyValueObservation?
        private var lastSlideID: String?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            observation = nil
            sizeObservation = nil
            guard window != nil else { return }
            var superview = superview
            while let view = superview, !(view is UIScrollView) {
                superview = view.superview
            }
            guard let scrollView = superview as? UIScrollView else { return }
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                MainActor.assumeIsolated {
                    self?.scrollViewDidMove(scrollView)
                }
            }
            sizeObservation = scrollView.observe(\.contentSize, options: [.old, .new]) { [weak self] scrollView, change in
                guard change.oldValue != change.newValue else { return }
                MainActor.assumeIsolated {
                    self?.keepCurrentSlide(in: scrollView)
                }
            }
        }

        /// The slides change height when the space around the pager changes, for example while a
        /// share sheet with a keyboard is on screen, or when the toolbar comes back. The offset does
        /// not follow, and the scroll view clamps it at the end of shorter content, so the pager would
        /// rest on another slide. `.scrollPosition(id:)` used to keep the slide; this does it now.
        private func keepCurrentSlide(in scrollView: UIScrollView) {
            guard !scrollView.isTracking, !scrollView.isDecelerating,
                  let lastSlideID,
                  let index = slideIDs.firstIndex(of: lastSlideID) else {
                return
            }
            let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
            guard pageHeight > 0 else { return }
            let offset = CGFloat(index) * pageHeight - scrollView.adjustedContentInset.top
            guard abs(scrollView.contentOffset.y - offset) >= 1 else { return }
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: offset), animated: false)
        }

        private func scrollViewDidMove(_ scrollView: UIScrollView) {
            // Only when the finger is up and the pager is exactly on a page, so not in the middle of a swipe.
            guard !scrollView.isTracking, !slideIDs.isEmpty else { return }
            let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
            guard pageHeight > 0 else { return }
            let page = ((scrollView.contentOffset.y + scrollView.adjustedContentInset.top) / pageHeight).rounded()
            guard abs(scrollView.contentOffset.y + scrollView.adjustedContentInset.top - page * pageHeight) < 1,
                  slideIDs.indices.contains(Int(page)) else {
                return
            }
            let slideID = slideIDs[Int(page)]
            guard slideID != lastSlideID else { return }
            lastSlideID = slideID
            onPageChange?(slideID)
        }
    }
}

private struct WMFYearInReviewPagingModifier: ViewModifier {

    /// Carries the position to VoiceOver, which cannot read it off the progress bar.
    let positionAccessibilityValue: String

    @ViewBuilder
    func body(content: Content) -> some View {
        let paged = content
            .scrollTargetBehavior(.viewAligned(limitBehavior: pageLimit))
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

