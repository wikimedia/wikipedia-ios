class TextFormattingInputView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 300)
    }
}

class TextFormattingInputViewController: UIInputViewController {
    private let storyboardName = "TextFormatting"
    @IBOutlet weak var containerView: UIView!

    private var textStyleFormattingTableViewController: TextStyleFormattingTableViewController
    private var textFormattingTableViewController: TextFormattingTableViewController

    weak var delegate: TextFormattingDelegate? {
        didSet{
            textStyleFormattingTableViewController.delegate = delegate
            textFormattingTableViewController.delegate = delegate
        }
    }
    private var theme = Theme.standard

    var selectedTextStyleType: TextStyleType?
    var selectedTextSizeType: TextSizeType?

    enum InputViewType {
        case textFormatting
        case textStyle
    }
    
    required init?(coder: NSCoder) {
        textStyleFormattingTableViewController = TextStyleFormattingTableViewController.wmf_viewControllerFromStoryboardNamed(storyboardName)
        textFormattingTableViewController = TextFormattingTableViewController.wmf_viewControllerFromStoryboardNamed(storyboardName)
        super.init(coder: coder)
    }

    var inputViewType = InputViewType.textFormatting {
        didSet {
            guard viewIfLoaded != nil else {
                return
            }
            let viewController = rootViewController(for: inputViewType)
            embeddedNavigationController.viewControllers = [viewController]
        }
    }

    private func rootViewController(for type: InputViewType) -> UIViewController {
        var viewController: TextFormattingProvidingTableViewController

        switch type {
        case .textFormatting:
            viewController = textFormattingTableViewController
        case .textStyle:
            viewController = textStyleFormattingTableViewController
        }
        viewController.apply(theme: theme)
        return viewController
    }

    private lazy var embeddedNavigationController: UINavigationController = {
        let viewController = rootViewController(for: inputViewType)
        let navigationController = UINavigationController(rootViewController: viewController)
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
        assert(containerView.subviews.isEmpty)
        containerView.addSubview(embeddedNavigationController.view)
        embeddedNavigationController.didMove(toParent: self)
    }

    private func addTopShadow() {
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1.0
    }

    // MARK: Text & button selection messages

    func textSelectionDidChange(isRangeSelected: Bool) {
        textFormattingTableViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
        textStyleFormattingTableViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }

    func buttonSelectionDidChange(button: SectionEditorWebViewMessagingController.Button) {
        textFormattingTableViewController.buttonSelectionDidChange(button: button)
        textStyleFormattingTableViewController.buttonSelectionDidChange(button: button)
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

