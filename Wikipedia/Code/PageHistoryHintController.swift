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

    override func toggle(presenter: HintPresentingViewController, context: HintController.Context?, theme: Theme) {
        super.toggle(presenter: presenter, context: context, theme: theme, setPrimaryColor: { (primaryColor: inout UIColor?) in
            primaryColor = UIColor.wmf_red
        }, setBackgroundColor: { (backgroundColor: inout UIColor?) in
            backgroundColor = UIColor.wmf_lightRed
        })
        setHintHidden(!isHintHidden)
    }
}

