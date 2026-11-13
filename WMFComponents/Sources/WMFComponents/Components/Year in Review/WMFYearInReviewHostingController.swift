import SwiftUI
import UIKit
import Combine
import UIKit.UIGestureRecognizerSubclass

public final class WMFYearInReviewHostingController: WMFComponentHostingController<WMFYearInReviewView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFYearInReviewViewModel
    private var cancellables = Set<AnyCancellable>()
    /// The color that `applyContentColor()` last gave the bar items.
    private var appliedContentColor: UIColor?
    /// The share button. It fades out as the end screen comes in.
    private var fadingOutToolbarViews: [UIView] = []
    /// The donate button of the end screen when the last slide does not have one. It fades in.
    private var fadingInToolbarViews: [UIView] = []

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFYearInReviewView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    /// On iPad, the supported orientations above are not enough when the app supports multitasking.
    /// iPadOS 26 and later honors this preference instead, but only while this screen is visible,
    /// and the system may not honor it.
    @available(iOS 26.0, *)
    public override var prefersInterfaceOrientationLocked: Bool {
        return true
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WMFYearInReviewViewModel.chromeBackgroundColor
        navigationController?.view.backgroundColor = WMFYearInReviewViewModel.chromeBackgroundColor

        viewModel.$currentSlideID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyContentColor()
                self?.configureToolbar()
                self?.refreshToolbarItems()
            }
            .store(in: &cancellables)

        // The end screen scrolls its light sky away from under the bar items, then they turn light.
        viewModel.$endUsesLightContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyContentColor()
            }
            .store(in: &cancellables)

        // The share and donate buttons fade, and the bar items change color, during the swipe to the
        // end screen, not when it ends.
        viewModel.endPageReveal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyContentColor()
                self?.applyToolbarReveal()
            }
            .store(in: &cancellables)

        // A slide can set the color of the controls in its .riv, which is known only after it loads.
        viewModel.$loadedContentStyles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyContentColor()
            }
            .store(in: &cancellables)

        // The donate button becomes a spinner while the donate configuration loads.
        viewModel.$isLoadingDonate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshToolbarItems()
            }
            .store(in: &cancellables)

        // The toolbar buttons and which of them fade depend on the end screen and the last slide.
        // They change without a page change, for example when the "Thank you" slide replaces
        // "You matter" after a donation from the end screen.
        Publishers.Merge3(
            viewModel.$endViewModel.map { _ in () },
            viewModel.$slides.map { _ in () },
            viewModel.$showsAnswersAsSlides.map { _ in () }
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshToolbarItems()
            }
            .store(in: &cancellables)

        // The view model is main actor isolated, so this publishes on the main thread already.
        viewModel.$isShowingSwipeOnboarding
            .removeDuplicates()
            .sink { [weak self] isShowing in
                self?.setSwipeOnboardingVisible(isShowing)
            }
            .store(in: &cancellables)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyMinimumToolbarClearance()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        viewModel.topSafeAreaInset = view.safeAreaInsets.top
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        // The bar items are new, and the navigation bar may not have had this color yet.
        appliedContentColor = nil
        applyContentColor()
        (navigationController as? WMFComponentNavigationController)?.setTransparentAppearance(true)
        configureToolbar()
        navigationController?.setToolbarHidden(false, animated: animated)
        refreshToolbarItems()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lockToPortraitOnIPad()

        // The slides are on screen now: presented, or swapped in for the announcement. Start the
        // 2-second wait, and if it started, watch for the reader's first touch anywhere on the
        // screen, the bars included. That touch hides the hint, or stops it from showing.
        guard let containerView = navigationController?.view,
              viewModel.scheduleSwipeOnboardingIfNeeded() else { return }
        containerView.addGestureRecognizer(WMFFirstTouchGestureRecognizer { [weak self] in
            self?.viewModel.dismissSwipeOnboarding()
        })
    }

    // MARK: - Swipe onboarding

    private var swipeOnboardingOverlay: UIView?

    /// The hint covers the whole screen, the navigation bar and the toolbar included. It does not
    /// take touches: the reader's first swipe moves the pager and hides the hint at the same time.
    private func setSwipeOnboardingVisible(_ isVisible: Bool) {
        if isVisible {
            guard swipeOnboardingOverlay == nil, let containerView = navigationController?.view else { return }
            let overlay = makeSwipeOnboardingOverlay()
            overlay.frame = containerView.bounds
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.alpha = 0
            containerView.addSubview(overlay)
            swipeOnboardingOverlay = overlay
            UIView.animate(withDuration: 0.3) {
                overlay.alpha = 1
            }
        } else {
            guard let overlay = swipeOnboardingOverlay else { return }
            swipeOnboardingOverlay = nil
            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                overlay.alpha = 0
            } completion: { _ in
                overlay.removeFromSuperview()
            }
        }
    }

    /// Black at partial opacity, the way the system dims content behind an alert, and the same as
    /// the For You feed's hint. No blur, so the slide stays recognisable.
    private func makeSwipeOnboardingOverlay() -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = WMFColor.black.withAlphaComponent(0.42)
        overlay.isUserInteractionEnabled = false
        overlay.accessibilityElementsHidden = true

        let imageView = UIImageView(image: WMFIcon.swipeUpGesture)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        return overlay
    }

    // MARK: - Orientation

    /// Asks for portrait, then asks the system to keep it while this screen shows.
    private func lockToPortraitOnIPad() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }

        if #available(iOS 26.0, *) {
            setNeedsUpdateOfPrefersInterfaceOrientationLocked()
        }
    }

    // MARK: - Toolbar

    private func configureToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }

        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        // The toolbar and the space around the page use the same color.
        appearance.backgroundColor = viewModel.currentChromeColor
        appearance.shadowColor = .clear

        toolbar.standardAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        toolbar.tintColor = WMFColor.white
    }

    
    private func applyMinimumToolbarClearance() {
        guard let toolbar = navigationController?.toolbar else { return }

        let occupied = toolbar.bounds.height + (view.window?.safeAreaInsets.bottom ?? 0)
        let deficit = max(0, WMFYearInReviewViewModel.toolbarMinimumHeight - occupied)

        if additionalSafeAreaInsets.bottom != deficit {
            additionalSafeAreaInsets.bottom = deficit
        }
    }

    private func refreshToolbarItems() {
        var items: [UIBarButtonItem] = []
        var fadingOutViews: [UIView] = []
        var fadingInViews: [UIView] = []

        // On the end screen, the share button is the one of the last slide, hidden by `applyToolbarReveal()`.
        if viewModel.toolbarShowsShareButton {
            let item = makeToolbarItem(
                title: viewModel.localizedStrings.shareButtonTitle,
                symbol: .share,
                action: #selector(tappedShare)
            )
            items.append(item)
            fadingOutViews += [item.customView].compactMap { $0 }
        }

        items.append(UIBarButtonItem(systemItem: .flexibleSpace))

        if viewModel.toolbarShowsDonateButton {
            let item: UIBarButtonItem
            if viewModel.isLoadingDonate {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = WMFColor.white
                spinner.startAnimating()
                item = UIBarButtonItem(customView: spinner)
            } else {
                item = makeToolbarItem(
                    title: viewModel.localizedStrings.donateButtonTitle,
                    symbol: .heartFilled,
                    action: #selector(tappedDonate)
                )
            }
            items.append(item)
            // The end screen keeps the donate button of the last slide, so only a button that the
            // last slide does not have fades.
            if viewModel.toolbarDonateButtonFadesIn {
                fadingInViews += [item.customView].compactMap { $0 }
            }
        }

        // The placeholder is always hidden, so it does not fade.
        fadingOutToolbarViews = fadingOutViews
        fadingInToolbarViews = fadingInViews

        // If the page has no toolbar buttons, add a placeholder.
        // The placeholder keeps the toolbar at the same height on all pages.
        if !viewModel.toolbarShowsShareButton && !viewModel.toolbarShowsDonateButton {
            items.append(makeToolbarPlaceholderItem())
        }

        setToolbarItems(items, animated: false)
        applyToolbarReveal()
    }

    /// The end screen has no share button. It fades out as the end screen comes in, and fades in as
    /// the reader swipes back, so it does not appear or disappear at once when the swipe ends. A donate
    /// button that only the end screen has fades the other way.
    private func applyToolbarReveal() {
        let reveal = viewModel.toolbarEndReveal
        for view in fadingOutToolbarViews {
            applyToolbarVisibility(to: view, alpha: 1 - reveal)
        }
        for view in fadingInToolbarViews {
            applyToolbarVisibility(to: view, alpha: reveal)
        }
    }

    /// A button that is less than half visible cannot be tapped and VoiceOver skips it.
    private func applyToolbarVisibility(to view: UIView, alpha: CGFloat) {
        let isHidden = alpha < 0.5
        view.alpha = alpha
        view.isUserInteractionEnabled = !isHidden
        view.accessibilityElementsHidden = isHidden
    }

    /// Makes an item that has the same size as a toolbar button, but the user cannot see it or use it.
    /// It uses the same button configuration, thus the height is always correct.
    private func makeToolbarPlaceholderItem() -> UIBarButtonItem {
        let item = makeToolbarItem(
            title: viewModel.localizedStrings.shareButtonTitle,
            symbol: .share,
            action: #selector(tappedToolbarPlaceholder)
        )

        if let button = item.customView {
            button.alpha = 0
            button.isUserInteractionEnabled = false
            button.accessibilityElementsHidden = true
        }

        return item
    }

    /// The placeholder item cannot receive taps. This method does nothing.
    @objc private func tappedToolbarPlaceholder() {}


    private func makeToolbarItem(title: String, symbol: WMFSFSymbolIcon, action: Selector) -> UIBarButtonItem {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = WMFSFSymbolIcon.for(symbol: symbol)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6
        configuration.baseForegroundColor = WMFColor.white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = WMFFont.for(.semiboldHeadline)
            return outgoing
        }

        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
   
        button.sizeToFit()

        let item = UIBarButtonItem(customView: button)

        
        if #available(iOS 26.0, *) {
            // iOS 26 puts a capsule behind a bar button item
            item.hidesSharedBackground = true
        }

        return item
    }

    @objc private func tappedShare() {
        viewModel.tappedShare()
    }

    @objc private func tappedDonate() {
        viewModel.tappedDonate(sourceRect: { [weak self] in
            guard let toolbar = self?.navigationController?.toolbar else { return .zero }
            return toolbar.convert(toolbar.bounds, to: nil)
        })
    }

    // MARK: - Navigation bar

    private func configureNavigationBar() {
        WMFYearInReviewNavigationItems.configure(
            self,
            strings: WMFYearInReviewNavigationItems.Strings(
                closeButtonAccessibilityLabel: viewModel.localizedStrings.closeButtonAccessibilityLabel,
                moreButtonAccessibilityLabel: viewModel.localizedStrings.moreButtonAccessibilityLabel,
                learnMoreTitle: viewModel.localizedStrings.learnMoreButtonTitle,
                aboutInsightsTitle: viewModel.localizedStrings.aboutInsightsButtonTitle,
                shareFeedbackTitle: viewModel.localizedStrings.shareFeedbackButtonTitle
            ),
            tintColor: contentColor,
            closeAction: #selector(tappedClose),
            onLearnMore: { [weak self] in self?.viewModel.tappedLearnMore() },
            onAboutInsights: { [weak self] in self?.viewModel.tappedAboutInsights() },
            onShareFeedback: { [weak self] in self?.viewModel.tappedShareFeedback() }
        )
    }

    /// Each slide says whether its artwork is light or dark, so the bar items follow the current slide.
    private func applyContentColor() {
        let color = contentColor
        // This runs on each slide change and each scroll step of the end screen. Do nothing if the color is the same.
        guard color != appliedContentColor else { return }
        appliedContentColor = color

        WMFYearInReviewNavigationItems.applyTintColor(color, to: navigationItem)
        navigationController?.navigationBar.tintColor = color
    }

    /// The color from the .riv once the slide has loaded, otherwise the style the factory gave it.
    private var contentColor: UIColor {
        viewModel.barContentColor ?? theme.text
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }

}

/// Reports the first touch that starts in its view, then turns itself off. It never delays or
/// cancels a touch, so the pager, the slides and the bar buttons get every touch as before.
private final class WMFFirstTouchGestureRecognizer: UIGestureRecognizer {

    private let onFirstTouch: @MainActor () -> Void

    init(onFirstTouch: @escaping @MainActor () -> Void) {
        self.onFirstTouch = onFirstTouch
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onFirstTouch()
        state = .failed
        isEnabled = false
    }
}
