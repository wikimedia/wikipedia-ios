import WMFComponents

class EditPreviewInternalLinkViewController: UIViewController {
    @IBOutlet private weak var containerView: UIView!
    private var containerViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var tapView: UIView!
    @IBOutlet private weak var tapGestureRecignizer: UITapGestureRecognizer!

    private let articleURL: URL
    private let dataStore: MWKDataStore
    private var theme = Theme.standard

    init(articleURL: URL, dataStore: MWKDataStore) {
        self.articleURL = articleURL
        self.dataStore = dataStore
        super.init(nibName: "EditPreviewInternalLinkViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        button.titleLabel?.font = WMFFont.for(.title3, compatibleWith: traitCollection)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        button.layer.cornerRadius = 8
        button.setTitle(CommonStrings.okTitle, for: .normal)
        wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme, containerView: containerView)
        tapGestureRecignizer.delegate = self
        tapGestureRecignizer.addTarget(self, action: #selector(dismissAnimated(_:)))
        updateFonts()
        apply(theme: theme)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if let containerViewHeightConstraint = containerViewHeightConstraint {
            containerViewHeightConstraint.constant = container.preferredContentSize.height
        } else {
            containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: container.preferredContentSize.height)
            containerViewHeightConstraint?.isActive = true
        }
    }

    @IBAction private func dismissAnimated(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension EditPreviewInternalLinkViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == tapView
    }
}

extension EditPreviewInternalLinkViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        button.backgroundColor = theme.colors.midBackground
        button.tintColor = theme.colors.link
    }
}
