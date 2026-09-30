import UIKit

/// Navigation bar items shared by the Year in Review slides and the announcement, so both show the
/// same W and the same more menu.
enum WMFYearInReviewNavigationItems {

    struct MoreMenuStrings {
        let moreButtonAccessibilityLabel: String
        let learnMoreTitle: String
        let aboutInsightsTitle: String
    }

    @MainActor
    static func makeTitleView(accessibilityLabel: String, tintColor: UIColor) -> UIView {
        let imageView = UIImageView(image: UIImage(named: "W", in: .module, with: nil))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = tintColor
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = accessibilityLabel
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 20)
        return imageView
    }

    @MainActor
    static func makeMoreButton(
        strings: MoreMenuStrings,
        tintColor: UIColor,
        onLearnMore: @escaping () -> Void,
        onAboutInsights: @escaping () -> Void
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

        let item = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .ellipsis),
            menu: UIMenu(children: [learnMore, aboutInsights])
        )
        item.accessibilityLabel = strings.moreButtonAccessibilityLabel
        item.tintColor = tintColor
        return item
    }
}
