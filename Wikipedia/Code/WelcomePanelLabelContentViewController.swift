import UIKit

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        label.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
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
