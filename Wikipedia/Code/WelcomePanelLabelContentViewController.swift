import WMFComponents

class WelcomePanelLabelContentViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    private let text: String
    private var theme = Theme.standard

    init(text: String) {
        self.text = text
        super.init(nibName: "WelcomePanelLabelContentViewController", bundle: Bundle.main)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = text
        updateFonts()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateFonts()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateFonts() {
        label.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }
}

extension WelcomePanelLabelContentViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.midBackground
        label.textColor = theme.colors.primaryText
        label.backgroundColor = theme.colors.midBackground
    }
}
