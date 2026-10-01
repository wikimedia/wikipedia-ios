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

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "",
            customView: makeTitleView(),
            alignment: .centerCompact
        )

        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(tappedClose),
            alignment: .leading
        )

        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        navigationItem.rightBarButtonItem = makeMoreButton()
        applyContentColor()
    }

    private func applyContentColor() {
        let color = viewModel.currentSlide?.contentColor ?? theme.text
        navigationItem.rightBarButtonItem?.tintColor = color
        navigationItem.leftBarButtonItem?.tintColor = color
        (navigationItem.titleView as? UIImageView)?.tintColor = color
    }

    private func makeTitleView() -> UIView {
        let imageView = UIImageView(image: UIImage(named: "W", in: .module, with: nil))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = viewModel.currentSlide?.contentColor ?? theme.text
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = viewModel.localizedStrings.wIconAccessibilityLabel
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 20)
        return imageView
    }

    private func makeMoreButton() -> UIBarButtonItem {
        let learnMore = UIAction(
            title: viewModel.localizedStrings.learnMoreButtonTitle,
            image: WMFSFSymbolIcon.for(symbol: .infoCircle)
        ) { [weak self] _ in
            self?.viewModel.tappedLearnMore()
        }

        let shareFeedback = UIAction(
            title: viewModel.localizedStrings.shareFeedbackButtonTitle,
            image: WMFSFSymbolIcon.for(symbol: .ellipsisBubble)
        ) { [weak self] _ in
            self?.viewModel.tappedShareFeedback()
        }

        let item = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .ellipsis),
            menu: UIMenu(children: [learnMore, shareFeedback])
        )
        item.accessibilityLabel = viewModel.localizedStrings.moreButtonAccessibilityLabel
        item.tintColor = viewModel.currentSlide?.contentColor ?? theme.text
        return item
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }

}
