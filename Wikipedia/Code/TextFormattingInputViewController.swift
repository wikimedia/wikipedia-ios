class TextFormattingInputView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 300)
    }
}

@objc(WMFTextFormattingInputViewController)
class TextFormattingInputViewController: UIInputViewController {
    weak var delegate: TextFormattingTableViewControllerDelegate?

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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id == "EmbedNavigationControllerForTextFormattingTableView" else {
            return
        }
        guard let navigationController = segue.destination as? UINavigationController else {
            return
        }
        guard let textFormattingTableViewController = navigationController.topViewController as? TextFormattingTableViewController else {
            return
        }
        textFormattingTableViewController.delegate = delegate
        textFormattingTableViewController.apply(theme: theme)
    }
    
}

extension TextFormattingInputViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        view.layer.shadowColor = theme.colors.shadow.cgColor
    }
}

