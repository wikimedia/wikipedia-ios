import Foundation
import WMF
import WKData

final class FundraisingAnnouncementPanelViewController: ScrollableEducationPanelViewController {

    private let announcement: WKFundraisingCampaignConfig.WKAsset

    init(announcement: WKFundraisingCampaignConfig.WKAsset, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler?,footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme) {
        self.announcement = announcement
        super.init(showCloseButton: true, showOptionaButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, optionalButtonTapHandler: optionalButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
        self.isUrgent = true
        self.footerLinkAction = footerLinkAction
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subheadingHTML = announcement.textHtml
        subheadingTextAlignment = .natural
        footerHTML = announcement.footerHtml
        spacing = 20
        buttonCornerRadius = 8
        buttonTopSpacing = 10
        primaryButtonTitleEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        dismissWhenTappedOutside = true
        contentHorizontalPadding = 20
        configureButtons()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        evaluateConstraintsOnNewSize(view.frame.size)
        subheadingTextView.textContainerInset = .zero
    }

    func configureButtons() {
        let actions = announcement.actions
        primaryButtonTitle = actions[0].title
        secondaryButtonTitle = actions[1].title
        optionalButtonTitle = actions[2].title
    }

    private func evaluateConstraintsOnNewSize(_ size: CGSize) {
        let panelWidth = size.width * 0.9
        if  traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            width = min(320, panelWidth)
        } else {
            width = panelWidth
        }
    }

}
