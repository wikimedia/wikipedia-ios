import SwiftUI
import UIKit
import Combine

public final class WMFYearInReviewHostingController: WMFComponentHostingController<WMFYearInReviewView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFYearInReviewViewModel
    private var cancellables = Set<AnyCancellable>()

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

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WMFYearInReviewViewModel.chromeBackgroundColor
        navigationController?.view.backgroundColor = WMFYearInReviewViewModel.chromeBackgroundColor

        viewModel.$currentSlideID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyContentColor()
                self?.refreshToolbarItems()
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
        (navigationController as? WMFComponentNavigationController)?.setTransparentAppearance(true)
        configureToolbar()
        navigationController?.setToolbarHidden(false, animated: animated)
        refreshToolbarItems()
    }

    // MARK: - Toolbar

    private func configureToolbar() {
        guard let toolbar = navigationController?.toolbar else { return }

        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = WMFYearInReviewViewModel.chromeBackgroundColor
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

        if viewModel.currentSlide?.showsShareButton == true {
            items.append(
                makeToolbarItem(
                    title: viewModel.localizedStrings.shareButtonTitle,
                    symbol: .share,
                    action: #selector(tappedShare)
                )
            )
        }

        items.append(UIBarButtonItem(systemItem: .flexibleSpace))

        if viewModel.showsDonateButton {
            if viewModel.isLoadingDonate {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = WMFColor.white
                spinner.startAnimating()
                items.append(UIBarButtonItem(customView: spinner))
            } else {
                items.append(
                    makeToolbarItem(
                        title: viewModel.localizedStrings.donateButtonTitle,
                        symbol: .heartFilled,
                        action: #selector(tappedDonate)
                    )
                )
            }
        }

        setToolbarItems(items, animated: false)
    }


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
        WMFYearInReviewNavigationItems.applyTintColor(contentColor, to: navigationItem)
    }

    /// The color from the .riv once the slide has loaded, otherwise the style the factory gave it.
    private var contentColor: UIColor {
        viewModel.currentContentColor ?? theme.text
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }

}
