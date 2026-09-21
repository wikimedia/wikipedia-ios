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
            }
            .store(in: &cancellables)
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        viewModel.topSafeAreaInset = view.safeAreaInsets.top
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        (navigationController as? WMFComponentNavigationController)?.setTransparentAppearance(true)
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
