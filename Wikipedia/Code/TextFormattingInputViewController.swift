@objc(WMFTextFormattingInputViewController)
class TextFormattingInputViewController: UIInputViewController {
    private var theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        addTopShadow()
        apply(theme: theme)
    }

    private func addTopShadow() {
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1.0
    }
}

extension TextFormattingInputViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.layer.shadowColor = theme.colors.shadow.cgColor
    }
}

