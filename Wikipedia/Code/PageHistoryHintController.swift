class PageHistoryHintViewController: HintViewController {
    override func configureSubviews() {
        defaultImageView.image = UIImage(named: "exclamation-point")
        defaultLabel.text = "Only two revisions can be selected"
    }
}

class PageHistoryHintController: HintController {
    @objc init() {
        let pageHistoryHintViewController = PageHistoryHintViewController()
        super.init(hintViewController: pageHistoryHintViewController)
    }

    public func hide(_ hide: Bool, presenter: HintPresentingViewController, theme: Theme) {
        super.toggle(presenter: presenter, context: nil, theme: theme, setPrimaryColor: { (primaryColor: inout UIColor?) in
            primaryColor = UIColor.wmf_red
        }, setBackgroundColor: { (backgroundColor: inout UIColor?) in
            backgroundColor = UIColor.wmf_lightRed
        })
        setHintHidden(hide)
    }
}

