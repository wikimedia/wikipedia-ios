import SwiftUI
import UIKit

public struct WMFYearInReviewView: View {

    @ObservedObject var viewModel: WMFYearInReviewViewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    /// The slide that asked to move to the next slide. See `WMFYearInReviewNextSlideScroller`.
    @State private var nextSlideRequest: String?

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
                    color: Color(uiColor: viewModel.currentContentColor ?? WMFColor.white)
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
                .background {
                    WMFYearInReviewPageObserver(slideIDs: viewModel.slides.map(\.id)) { slideID in
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
                }
                .scrollTargetLayout()
                .background {
                    WMFYearInReviewPageObserver(slideIDs: viewModel.slides.map(\.id)) { slideID in
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

    /// `ForEach` iterates the slides directly, so that each slide keeps its identity.
    @ViewBuilder
    private var slideViews: some View {
        ForEach(viewModel.slides) { slide in
            WMFYearInReviewSlideView(
                slide: slide,
                isCurrent: slide.id == viewModel.currentSlideID,
                onLightContentFlag: { lightContent in
                    viewModel.slideDidLoad(lightContent: lightContent, slideID: slide.id)
                },
                onNextSlideTrigger: {
                    guard slide.id == viewModel.currentSlideID else { return }
                    nextSlideRequest = slide.id
                },
                donateButtonTitle: viewModel.localizedStrings.donateButtonTitle,
                isLoadingDonate: viewModel.isLoadingDonate,
                onTapDonate: { sourceRect in
                    viewModel.tappedDonate(sourceRect: sourceRect)
                }
            )
                .background {
                    WMFYearInReviewNextSlideScroller(isRequested: nextSlideRequest == slide.id) {
                        nextSlideRequest = nil
                    }
                }
                .containerRelativeFrame(.vertical)
                .id(slide.id)
        }
    }
}

/// Moves the pager to the next slide, the same as a swipe. `WMFYearInReviewPageObserver` then
/// updates `currentSlideID`.
private struct WMFYearInReviewNextSlideScroller: UIViewRepresentable {

    let isRequested: Bool
    let onScroll: @MainActor () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard isRequested else { return }
        // Not during the view update, which must not change state.
        Task { @MainActor in onScroll() }

        var superview = uiView.superview
        while let view = superview, !(view is UIScrollView) {
            superview = view.superview
        }
        guard let scrollView = superview as? UIScrollView else { return }

        let slideFrame = uiView.convert(uiView.bounds, to: scrollView)
        let maximumOffset = scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.bounds.height
        let offset = min(slideFrame.maxY - scrollView.adjustedContentInset.top, maximumOffset)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
            scrollView.contentOffset.y = offset
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
        private var lastSlideID: String?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            observation = nil
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
            .scrollTargetBehavior(.paging)
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

