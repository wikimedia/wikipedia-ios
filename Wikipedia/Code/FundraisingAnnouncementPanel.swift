import Foundation
import WMF
import WKData

final class FundraisingAnnouncementPanelViewController: ScrollableEducationPanelViewController {

    private let announcement: WKFundraisingCampaignConfig.WKAsset

    init(announcement: WKFundraisingCampaignConfig.WKAsset, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler?,footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme, showOptionalButton: Bool) {
        self.announcement = announcement
        super.init(showCloseButton: true, showOptionalButton: showOptionalButton, newAnnouncement: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, optionalButtonTapHandler: optionalButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
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
        if showOptionalButton {
            secondaryButtonTitle = actions[1].title
            optionalButtonTitle = actions[2].title
        } else {
            secondaryButtonTitle = actions[2].title
        }
    }

    func shouldShowMaybeLater() -> Bool {
        return true
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
