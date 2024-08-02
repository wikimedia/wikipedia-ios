import Foundation
import WMF
import WMFData

final class FundraisingAnnouncementPanelViewController: ScrollableEducationPanelViewController {

    private let announcement: WMFFundraisingCampaignConfig.WMFAsset

    init(announcement: WMFFundraisingCampaignConfig.WMFAsset, theme: Theme, showOptionalButton: Bool ,primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, footerLinkAction: ((URL) -> Void)?) {
        self.announcement = announcement
        super.init(showCloseButton: true, showOptionalButton: showOptionalButton, buttonStyle: .updatedStyle, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, optionalButtonTapHandler: optionalButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
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
        if UIDevice.current.userInterfaceIdiom == .phone {
            containerStackViewBottomConstraint.constant = 45
            gradientView.fadeHeight = 40
            gradientView.fadeTop = false
            gradientView.apply(theme: theme)
            gradientView.isHidden = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.flashScrollIndicators()
        evaluateConstraintsOnNewSize(view.frame.size)
        subheadingTextView.textContainerInset = .zero
    }

    func configureButtons() {
        let actions = announcement.actions

        guard actions.count == 3 else {
            return
        }
        primaryButtonTitle = actions[0].title
        if showOptionalButton {
            secondaryButtonTitle = actions[1].title
            optionalButtonTitle = actions[2].title
        } else {
            secondaryButtonTitle = actions[2].title
        }
    }

    private func evaluateConstraintsOnNewSize(_ size: CGSize) {
        let panelWidth = size.width * 0.9
        if  traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            width = min(600, panelWidth)
        } else {
            width = panelWidth
        }
    }

}
