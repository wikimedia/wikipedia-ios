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
    
    required init?(coder: NSCoder) {
        textStyleFormattingTableViewController = TextStyleFormattingTableViewController.wmf_viewControllerFromStoryboardNamed(storyboardName)
        textFormattingTableViewController = TextFormattingTableViewController.wmf_viewControllerFromStoryboardNamed(storyboardName)
        super.init(coder: coder)
    }

    enum InputViewType {
        case textFormatting
        case textStyle
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

    private func rootViewController(for type: InputViewType) -> UIViewController & Themeable {
        var viewController: TextFormattingProvidingTableViewController

        switch type {
        case .textFormatting:
            viewController = textFormattingTableViewController
        case .textStyle:
            viewController = textStyleFormattingTableViewController
        }
        return viewController
    }

    private lazy var embeddedNavigationController: UINavigationController = {
        let viewController = rootViewController(for: inputViewType)
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        embedNavigationController()
        apply(theme: theme)
    }

    private func embedNavigationController() {
        addChild(embeddedNavigationController)
        embeddedNavigationController.view.frame = containerView.frame
        assert(containerView.subviews.isEmpty)
        containerView.addSubview(embeddedNavigationController.view)
        embeddedNavigationController.didMove(toParent: self)
    }

    // MARK: Text & button selection messages

    func textSelectionDidChange(isRangeSelected: Bool) {
        textFormattingTableViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
        textStyleFormattingTableViewController.textSelectionDidChange(isRangeSelected: isRangeSelected)
    }

    func buttonSelectionDidChange(button: SectionEditorButton) {
        textFormattingTableViewController.buttonSelectionDidChange(button: button)
        textStyleFormattingTableViewController.buttonSelectionDidChange(button: button)
    }
    
    func disableButton(button: SectionEditorButton) {
        textFormattingTableViewController.disableButton(button: button)
        textStyleFormattingTableViewController.disableButton(button: button)
    }
}

extension TextFormattingInputViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        textStyleFormattingTableViewController.apply(theme: theme)
        textFormattingTableViewController.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.inputAccessoryBackground
        if theme.hasInputAccessoryShadow {
            view.layer.shadowOffset = CGSize(width: 0, height: -2)
            view.layer.shadowRadius = 10
            view.layer.shadowOpacity = 1.0
            view.layer.shadowColor = theme.colors.shadow.cgColor
        } else {
            view.layer.shadowOffset = .zero
            view.layer.shadowRadius = 0
            view.layer.shadowOpacity = 0
            view.layer.shadowColor = nil
        }
        embeddedNavigationController.navigationBar.isTranslucent = false
        embeddedNavigationController.navigationBar.barTintColor = theme.colors.inputAccessoryBackground
        embeddedNavigationController.navigationBar.tintColor = theme.colors.inputAccessoryButtonTint
        embeddedNavigationController.navigationBar.titleTextAttributes = theme.navigationBarTitleTextAttributes
    }
}

