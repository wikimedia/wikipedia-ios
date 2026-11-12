import SwiftUI
import UIKit

public struct WMFYearInReviewView: View {

    @ObservedObject var viewModel: WMFYearInReviewViewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    /// After a three-finger scroll, VoiceOver keeps the focus on the pager and reads only the page
    /// number. The focus goes to the slide content so that VoiceOver reads the slide.
    @AccessibilityFocusState private var focusedSlideID: String?
    /// A VoiceOver three-finger scroll asks for this page. See `accessibilityScroll(toward:)`.
    @State private var pageRequest: WMFYearInReviewPageRequest?

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
                    pageCount: viewModel.pageCount,
                    position: viewModel.pagerPosition
                )
                .padding(.trailing, WMFYearInReviewViewModel.progressBarEdgeInset)
                .padding(.top, viewModel.progressBarTopInset)
                // The track stops above the rounded corners, as on Android
                .padding(.bottom, WMFYearInReviewViewModel.slideCornerRadius)
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(uiColor: viewModel.currentChromeColor))
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentSlideID)
            .onAppear {
                viewModel.onAppear()
            }
            .task(id: viewModel.currentSlideID) {
                guard voiceOverEnabled, let slideID = viewModel.currentSlideID else { return }
                // A focus change while the pager still moves is lost.
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                focusedSlideID = nil
                focusedSlideID = slideID
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
                    WMFYearInReviewPageObserver(
                        slideIDs: viewModel.pageIDs,
                        pageRequest: pageRequest,
                        dragLockPageID: viewModel.endViewModel == nil ? nil : WMFYearInReviewViewModel.endPageID,
                        onPageChange: { slideID in
                            viewModel.currentSlideID = slideID
                        },
                        onScroll: { position in
                            viewModel.pagerDidScroll(toPosition: position)
                        }
                    )
                }
            }
            .modifier(WMFYearInReviewPagingModifier())
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    slideViews
                    endPage
                }
                .scrollTargetLayout()
                .background {
                    WMFYearInReviewPageObserver(
                        slideIDs: viewModel.pageIDs,
                        pageRequest: pageRequest,
                        dragLockPageID: viewModel.endViewModel == nil ? nil : WMFYearInReviewViewModel.endPageID,
                        onPageChange: { slideID in
                            viewModel.currentSlideID = slideID
                        },
                        onScroll: { position in
                            viewModel.pagerDidScroll(toPosition: position)
                        }
                    )
                }
            }
            .modifier(WMFYearInReviewPagingModifier())
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
                },
                shareHighlightsTitle: viewModel.showsShareHighlightsButton ? viewModel.localizedStrings.shareHighlightsButtonTitle : nil,
                onShareHighlights: { sourceRect in
                    viewModel.tappedShareHighlights(sourceRect: sourceRect)
                },
                onPullDownPastTop: {
                    goBackFromEnd()
                }
            )
                .containerRelativeFrame(.vertical)
                .id(WMFYearInReviewViewModel.endPageID)
                .accessibilityHidden(isHiddenFromVoiceOver(WMFYearInReviewViewModel.endPageID))
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
                accessibilityFocus: $focusedSlideID,
                onAccessibilityScroll: accessibilityScrollHandler,
                accessibilityScrollHint: viewModel.localizedStrings.slideAccessibilityHint,
                revealAccessibilityHint: viewModel.localizedStrings.revealAnswerAccessibilityHint,
                onAnswerShown: {
                    viewModel.answerDidShow(slideID: slide.id)
                },
                donateButtonTitle: viewModel.localizedStrings.donateButtonTitle,
                isLoadingDonate: viewModel.isLoadingDonate,
                onTapDonate: { sourceRect in
                    viewModel.tappedDonate(sourceRect: sourceRect)
                }
            )
                .containerRelativeFrame(.vertical)
                .id(slide.id)
                .accessibilityHidden(isHiddenFromVoiceOver(slide.id))
        }
    }

    /// VoiceOver reaches only the current page. A one-finger swipe then goes from the page to the
    /// toolbar and the navigation bar, not to the next slide. A three-finger scroll changes the page.
    private func isHiddenFromVoiceOver(_ pageID: String) -> Bool {
        voiceOverEnabled && pageID != viewModel.currentSlideID
    }

    private var accessibilityScrollHandler: (@MainActor (Edge) -> Void)? {
        guard voiceOverEnabled else { return nil }
        return { edge in accessibilityScroll(toward: edge) }
    }

    /// VoiceOver sends a three-finger scroll to the focused slide before the ScrollView. The
    /// ScrollView scrolls by its own page size, which is not the slide height, and reads
    /// "page N of M" with the focus left on the pager. Here the pager moves exactly one slide,
    /// and the focus then goes to the new slide.
    private func accessibilityScroll(toward edge: Edge) {
        let step: Int
        switch edge {
        case .bottom: step = 1
        case .top: step = -1
        default: return
        }
        let pageIDs = viewModel.pageIDs
        let index = viewModel.currentPageIndex + step
        guard pageIDs.indices.contains(index) else { return }
        pageRequest = WMFYearInReviewPageRequest(pageID: pageIDs[index], serial: (pageRequest?.serial ?? 0) + 1)
    }

    /// The pager does not take drags on the end screen. A pull down past its top goes back to the last slide.
    private func goBackFromEnd() {
        guard viewModel.isOnEnd, let lastSlideID = viewModel.pagerSlides.last?.id else { return }
        pageRequest = WMFYearInReviewPageRequest(pageID: lastSlideID, serial: (pageRequest?.serial ?? 0) + 1)
    }
}

private struct WMFYearInReviewPageRequest: Equatable {
    let pageID: String
    /// Makes a new request for the same page different from the last one.
    let serial: Int
}

/// Sets the current slide when the pager rests on a page: after a swipe, a VoiceOver scroll or a
/// move from code. It reads the `UIScrollView`, not `.scrollPosition(id:)`. That binding does not
/// see a scroll from code, and a change of the binding from code stops about a third of a slide past
/// the slide (the scroll view has a bottom content inset under the toolbar; seen on iOS 26.5).
private struct WMFYearInReviewPageObserver: UIViewRepresentable {

    let slideIDs: [String]
    let pageRequest: WMFYearInReviewPageRequest?
    /// On this page, the pager does not take drags, because the page has its own vertical scroll view
    /// (the end screen). When both took drags, the pager often won, bounced at its end and looked stuck.
    let dragLockPageID: String?
    let onPageChange: @MainActor (String) -> Void
    /// The page at the top of the pager, with a fraction, on each scroll step.
    let onScroll: @MainActor (CGFloat) -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        uiView.slideIDs = slideIDs
        uiView.onPageChange = onPageChange
        uiView.onScroll = onScroll
        uiView.dragLockPageID = dragLockPageID
        if let pageRequest {
            uiView.move(to: pageRequest)
        }
    }

    final class ObserverView: UIView {
        var slideIDs: [String] = []
        var onPageChange: (@MainActor (String) -> Void)?
        var onScroll: (@MainActor (CGFloat) -> Void)?
        var dragLockPageID: String? {
            didSet { applyDragLock() }
        }
        private var observation: NSKeyValueObservation?
        private var sizeObservation: NSKeyValueObservation?
        private var lastSlideID: String?
        private var settleTask: Task<Void, Never>?
        private weak var scrollView: UIScrollView?
        private var lastPageRequestSerial = 0

        /// The lock starts when the finger is up and the pager is more than half way to the locked
        /// page, so also while the pager still settles on it. A drag in that time went to the pager.
        /// The lock stops when the pager moves back more than half way, for example to the last slide.
        ///
        /// Only the pan gesture is turned off. SwiftUI owns `isScrollEnabled`, and a scroll from code
        /// or from VoiceOver still works.
        private func applyDragLock() {
            guard let scrollView, !scrollView.isTracking else { return }
            var locks = false
            if let dragLockPageID,
               let index = slideIDs.firstIndex(of: dragLockPageID),
               scrollView.contentSize.height > 0 {
                let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
                let position = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) / pageHeight
                locks = position > CGFloat(index) - 0.5
            }
            if scrollView.panGestureRecognizer.isEnabled == locks {
                scrollView.panGestureRecognizer.isEnabled = !locks
            }
        }

        func move(to request: WMFYearInReviewPageRequest) {
            guard request.serial != lastPageRequestSerial else { return }
            lastPageRequestSerial = request.serial
            guard let scrollView, let index = slideIDs.firstIndex(of: request.pageID) else { return }
            let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
            guard pageHeight > 0 else { return }
            let offset = CGFloat(index) * pageHeight - scrollView.adjustedContentInset.top
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: offset), animated: true)
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            observation = nil
            sizeObservation = nil
            settleTask?.cancel()
            settleTask = nil
            guard window != nil else { return }
            var superview = superview
            while let view = superview, !(view is UIScrollView) {
                superview = view.superview
            }
            guard let scrollView = superview as? UIScrollView else { return }
            self.scrollView = scrollView
            applyDragLock()
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
            settleTask?.cancel()
            if !slideIDs.isEmpty, scrollView.contentSize.height > 0 {
                let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
                onScroll?((scrollView.contentOffset.y + scrollView.adjustedContentInset.top) / pageHeight)
            }
            applyDragLock()

            // Only when the finger is up and the pager is exactly on a page, so not in the middle of a swipe.
            guard !scrollView.isTracking, !slideIDs.isEmpty else { return }
            let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
            guard pageHeight > 0 else { return }
            let page = ((scrollView.contentOffset.y + scrollView.adjustedContentInset.top) / pageHeight).rounded()
            guard abs(scrollView.contentOffset.y + scrollView.adjustedContentInset.top - page * pageHeight) < 1,
                  slideIDs.indices.contains(Int(page)) else {
                scheduleSettle(in: scrollView)
                return
            }
            let slideID = slideIDs[Int(page)]
            guard slideID != lastSlideID else { return }
            lastSlideID = slideID
            onPageChange?(slideID)
        }

        /// A VoiceOver three-finger scroll ignores `.scrollTargetBehavior(.paging)`. It moves by its
        /// own page size, which is not the slide height, so the pager stops between two slides.
        /// When the pager stops moving, this puts it on the nearest slide.
        private func scheduleSettle(in scrollView: UIScrollView) {
            settleTask = Task { [weak self, weak scrollView] in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, let self, let scrollView else { return }
                self.moveToNearestSlide(in: scrollView)
            }
        }

        private func moveToNearestSlide(in scrollView: UIScrollView) {
            guard !scrollView.isTracking, !scrollView.isDragging, !scrollView.isDecelerating,
                  !slideIDs.isEmpty else {
                return
            }
            let pageHeight = scrollView.contentSize.height / CGFloat(slideIDs.count)
            guard pageHeight > 0 else { return }
            let position = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) / pageHeight
            let page = min(max(position.rounded(), 0), CGFloat(slideIDs.count - 1))
            let offset = page * pageHeight - scrollView.adjustedContentInset.top
            guard abs(scrollView.contentOffset.y - offset) >= 1 else { return }
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: offset), animated: true)
        }
    }
}

private struct WMFYearInReviewPagingModifier: ViewModifier {

    // No accessibility element or value on the pager: VoiceOver then kept the focus on the pager
    // after a three-finger scroll, and read only the page number.
    @ViewBuilder
    func body(content: Content) -> some View {
        let paged = content
            .scrollTargetBehavior(.viewAligned(limitBehavior: pageLimit))
            .scrollIndicators(.hidden)

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

