class TextFormattingInputView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 300)
    }
}

class TextFormattingInputViewController: UIInputViewController {
    @IBOutlet weak var containerView: UIView!

    weak var delegate: TextFormattingTableViewControllerDelegate?

    enum InputViewType {
        case textFormatting
        case textStyle
    }

    var inputViewType = InputViewType.textFormatting

    private var theme = Theme.standard

    private lazy var embeddedNavigationController: UINavigationController = {
        let rootViewControllerType: (UIViewController & Themeable).Type

        if inputViewType == .textFormatting {
            rootViewControllerType = TextFormattingTableViewController.self
        } else {
            rootViewControllerType = TextStyleFormattingTableViewController.self
        }

        let storyboardName = "TextFormatting"
        let rootViewController = rootViewControllerType.wmf_viewControllerFromStoryboardNamed(storyboardName)
        rootViewController.apply(theme: theme)
        
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.isTranslucent = false

        return navigationController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        embedNavigationController()
        addTopShadow()
        apply(theme: theme)
    }

    private func embedNavigationController() {
        addChild(embeddedNavigationController)
        embeddedNavigationController.view.frame = containerView.frame
        containerView.addSubview(embeddedNavigationController.view)
        embeddedNavigationController.didMove(toParent: self)
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
        view.backgroundColor = theme.colors.paperBackground
        view.layer.shadowColor = theme.colors.shadow.cgColor
    }
}

