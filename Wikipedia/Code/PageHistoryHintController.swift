class PageHistoryHintViewController: HintViewController {
    override func configureSubviews() {
        defaultImageView.image = UIImage(named: "exclamation-point")
        defaultLabel.text = CommonStrings.maxRevisionsSelectedWarningTitle
    }
}

class PageHistoryHintController: HintController {
    @objc init() {
        let pageHistoryHintViewController = PageHistoryHintViewController()
        super.init(hintViewController: pageHistoryHintViewController)
    }

    public func hide(_ hide: Bool, presenter: HintPresentingViewController, subview: UIView, additionalBottomSpacing: CGFloat, theme: Theme) {
        super.toggle(presenter: presenter, context: nil, theme: theme, subview: subview, additionalBottomSpacing: additionalBottomSpacing, setPrimaryColor: { (primaryColor: inout UIColor?) in
            primaryColor = UIColor.wmf_red
        }) { (backgroundColor: inout UIColor?) in
            backgroundColor = UIColor.wmf_lightRed
        }
        setHintHidden(hide)
    }
}

