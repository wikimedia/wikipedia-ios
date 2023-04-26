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
            primaryColor = .red600
        }) { (backgroundColor: inout UIColor?) in
            backgroundColor = .red100
        }
        setHintHidden(hide)
    }
}

