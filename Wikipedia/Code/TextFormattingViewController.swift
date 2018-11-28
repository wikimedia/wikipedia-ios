import UIKit

@objc(WMFTextFormattingViewControllerDelegate)
protocol TextFormattingViewControllerDelegate: class {
    func textFormattingViewControllerDidTapCloseButton(_ textFormattingViewController: TextFormattingViewController, button: UIButton)
}

@objc(WMFTextFormattingViewController)
class TextFormattingViewController: UIViewController {
    @objc weak var delegate: TextFormattingViewControllerDelegate?

    private var theme = Theme.standard

    @objc static func loadFromNib() -> TextFormattingViewController {
        return TextFormattingViewController(nibName: "TextFormattingViewController", bundle: Bundle.main)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }

    @IBAction private func close(_ sender: UIButton) {
        delegate?.textFormattingViewControllerDidTapCloseButton(self, button: sender)
    }

    @IBAction private func showStyles(_ sender: UIButton) {
        let textStyleViewController = TextStyleViewController.loadFromNib()
    }
}

extension TextFormattingViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        guard let view = view as? Themeable else {
            return
        }
        view.apply(theme: theme)
    }
}
