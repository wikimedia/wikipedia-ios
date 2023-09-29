import Foundation
import WMF

final class FundraisingAnnouncementPanelViewController: ScrollableEducationPanelViewController {

    private let announcement: WKAsset

    init(announcement: WKAsset, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler?,footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme) {
        self.announcement = announcement
        super.init(showCloseButton: false, showOptionaButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, optionalButtonTapHandler: optionalButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
        self.isUrgent = true
        self.footerLinkAction = footerLinkAction
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //    override func viewDidLayoutSubviews() {
    //        super.viewDidLayoutSubviews()
    //
    //        evaluateConstraintsOnNewSize(view.frame.size)
    //    }

    override func viewIsAppearing(_ animated: Bool) { // testing this new method
        super.viewIsAppearing(animated)
        evaluateConstraintsOnNewSize(view.frame.size)
    }

    private func evaluateConstraintsOnNewSize(_ size: CGSize) { // check to see if it's relevant
        let panelWidth = size.width * 0.9
        if  traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            width = min(320, panelWidth)
        } else {
            width = panelWidth
        }
        // avoid scrolling on SE landscape, otherwise add a bit of padding
        let subheadingExtraTopBottomSpacing = size.height <= 320 ? 0 : CGFloat(10)
        subheadingTopConstraint.constant = originalSubheadingTopConstraint + CGFloat(subheadingExtraTopBottomSpacing)
        subheadingBottomConstraint.constant = originalSubheadingTopConstraint + CGFloat(subheadingExtraTopBottomSpacing)
    }

}
