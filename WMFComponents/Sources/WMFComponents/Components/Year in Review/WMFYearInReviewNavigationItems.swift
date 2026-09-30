import UIKit

/// The navigation bar shared by the Year in Review slides and the announcement: the close button,
/// the W, and the more menu.
enum WMFYearInReviewNavigationItems {

    struct Strings {
        let wIconAccessibilityLabel: String
        let closeButtonAccessibilityLabel: String
        let moreButtonAccessibilityLabel: String
        let learnMoreTitle: String
        let aboutInsightsTitle: String
        let shareFeedbackTitle: String
    }

    /// Sets up the whole navigation bar. `closeAction` is called on `viewController`.
    @MainActor
    static func configure<ViewController: UIViewController & WMFNavigationBarConfiguring>(
        _ viewController: ViewController,
        strings: Strings,
        tintColor: UIColor,
        closeAction: Selector,
        onLearnMore: @escaping () -> Void,
        onAboutInsights: @escaping () -> Void,
        onShareFeedback: @escaping () -> Void
    ) {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "",
            customView: makeTitleView(accessibilityLabel: strings.wIconAccessibilityLabel),
            alignment: .centerCompact
        )

        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: viewController,
            action: closeAction,
            alignment: .leading
        )

        viewController.configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        viewController.navigationItem.rightBarButtonItem = makeMoreButton(
            strings: strings,
            onLearnMore: onLearnMore,
            onAboutInsights: onAboutInsights,
            onShareFeedback: onShareFeedback
        )
        viewController.navigationItem.leftBarButtonItem?.accessibilityLabel = strings.closeButtonAccessibilityLabel

        applyTintColor(tintColor, to: viewController.navigationItem)
    }

    /// Colors the close button, the W and the more button. The slides call this again when the slide
    /// changes, since each slide's artwork can be light or dark.
    @MainActor
    static func applyTintColor(_ color: UIColor, to navigationItem: UINavigationItem) {
        navigationItem.leftBarButtonItem?.tintColor = color
        navigationItem.rightBarButtonItem?.tintColor = color
        navigationItem.titleView?.tintColor = color
    }

    // MARK: - Private

    @MainActor
    private static func makeTitleView(accessibilityLabel: String) -> UIView {
        let imageView = UIImageView(image: UIImage(named: "W", in: .module, with: nil))
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = accessibilityLabel
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 20)
        return imageView
    }

    @MainActor
    private static func makeMoreButton(
        strings: Strings,
        onLearnMore: @escaping () -> Void,
        onAboutInsights: @escaping () -> Void,
        onShareFeedback: @escaping () -> Void
    ) -> UIBarButtonItem {
        let learnMore = UIAction(
            title: strings.learnMoreTitle,
            image: WMFSFSymbolIcon.for(symbol: .infoCircle)
        ) { _ in
            onLearnMore()
        }

        let aboutInsights = UIAction(
            title: strings.aboutInsightsTitle,
            image: WMFSFSymbolIcon.for(symbol: .questionMarkBubble)
        ) { _ in
            onAboutInsights()
        }

        let shareFeedback = UIAction(
            title: strings.shareFeedbackTitle,
            image: WMFSFSymbolIcon.for(symbol: .ellipsisBubble)
        ) { _ in
            onShareFeedback()
        }

        let item = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .ellipsis),
            menu: UIMenu(children: [learnMore, aboutInsights, shareFeedback])
        )
        item.accessibilityLabel = strings.moreButtonAccessibilityLabel
        return item
    }
}
