import SwiftUI
import UIKit
import Combine

public final class WMFYearInReviewHostingController: WMFComponentHostingController<WMFYearInReviewView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFYearInReviewViewModel
    private var cancellables = Set<AnyCancellable>()
    /// The color that `applyContentColor()` last gave the bar items.
    private var appliedContentColor: UIColor?
    /// The share and donate views in the toolbar. They fade out while the end screen comes in.
    private var fadingToolbarViews: [UIView] = []
    /// The "Share highlights" button. It fades in while the end screen comes in.
    private var shareHighlightsButton: UIButton?

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

        // On the end screen, these are the buttons of the last slide, hidden by `applyToolbarReveal()`.
        let shareButton = viewModel.toolbarShowsShareButton
            ? makeToolbarButton(title: viewModel.localizedStrings.shareButtonTitle, symbol: .share, action: #selector(tappedShare))
            : nil
        let shareHighlightsButton = viewModel.toolbarShowsShareHighlightsButton
            ? makeToolbarButton(title: viewModel.localizedStrings.shareHighlightsButtonTitle, symbol: .share, action: #selector(tappedShareHighlights))
            : nil
        self.shareHighlightsButton = shareHighlightsButton

        switch (shareButton, shareHighlightsButton) {
        case let (shareButton?, shareHighlightsButton?):
            // One fades out while the other fades in, so they take the same place.
            items.append(makeToolbarItem(stacking: [shareButton, shareHighlightsButton]))
        case let (button?, nil), let (nil, button?):
            items.append(makeToolbarItem(button))
        case (nil, nil):
            break
        }

        items.append(UIBarButtonItem(systemItem: .flexibleSpace))

        var donateView: UIView?
        if viewModel.toolbarShowsDonateButton {
            if viewModel.isLoadingDonate {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = WMFColor.white
                spinner.startAnimating()
                donateView = spinner
            } else {
                donateView = makeToolbarButton(
                    title: viewModel.localizedStrings.donateButtonTitle,
                    symbol: .heartFilled,
                    action: #selector(tappedDonate)
                )
            }
        }
        if let donateView {
            items.append(makeToolbarItem(donateView))
        }

        // The placeholder is always hidden, so it does not fade.
        fadingToolbarViews = [shareButton, donateView].compactMap { $0 }

        // If the page has no toolbar buttons, add a placeholder.
        // The placeholder keeps the toolbar at the same height on all pages.
        if shareButton == nil && shareHighlightsButton == nil && !viewModel.toolbarShowsDonateButton {
            items.append(makeToolbarPlaceholderItem())
        }

        setToolbarItems(items, animated: false)
        applyToolbarReveal()
    }

    /// The end screen has no share or donate button of a slide. They fade out as it comes in, and fade
    /// in as the reader swipes back, so they do not appear or disappear at once when the swipe ends.
    /// "Share highlights" does the opposite.
    private func applyToolbarReveal() {
        let reveal = viewModel.endPageReveal.value
        let isOnEnd = reveal > 0.5
        for view in fadingToolbarViews {
            view.alpha = 1 - reveal
            view.isUserInteractionEnabled = !isOnEnd
            view.accessibilityElementsHidden = isOnEnd
        }
        if let shareHighlightsButton {
            shareHighlightsButton.alpha = reveal
            shareHighlightsButton.isUserInteractionEnabled = isOnEnd
            shareHighlightsButton.accessibilityElementsHidden = !isOnEnd
        }
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
        makeToolbarItem(makeToolbarButton(title: title, symbol: symbol, action: action))
    }

    private func makeToolbarButton(title: String, symbol: WMFSFSymbolIcon, action: Selector) -> UIButton {
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
        return button
    }

    /// One item that holds `buttons` on top of each other, at its leading edge, as wide as the widest.
    private func makeToolbarItem(stacking buttons: [UIButton]) -> UIBarButtonItem {
        let container = UIView()
        for button in buttons {
            button.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
                button.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
                button.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }
        let size = buttons.reduce(CGSize.zero) { size, button in
            CGSize(width: max(size.width, button.bounds.width), height: max(size.height, button.bounds.height))
        }
        container.frame = CGRect(origin: .zero, size: size)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: size.width),
            container.heightAnchor.constraint(equalToConstant: size.height)
        ])
        return makeToolbarItem(container)
    }

    private func makeToolbarItem(_ view: UIView) -> UIBarButtonItem {
        let item = UIBarButtonItem(customView: view)

        if #available(iOS 26.0, *) {
            // iOS 26 puts a capsule behind a bar button item
            item.hidesSharedBackground = true
        }

        return item
    }

    @objc private func tappedShare() {
        viewModel.tappedShare()
    }

    @objc private func tappedShareHighlights() {
        viewModel.tappedShareHighlights()
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
                wIconAccessibilityLabel: viewModel.localizedStrings.wIconAccessibilityLabel,
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
