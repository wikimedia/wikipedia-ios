import UIKit

class WelcomePanelLabelContentViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    private let text: String

    init(text: String) {
        self.text = text
        super.init(nibName: "WelcomePanelLabelContentViewController", bundle: Bundle.main)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.font  = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
}

extension WelcomePanelLabelContentViewController: Themeable {
    func apply(theme: Theme) {

    }
}
