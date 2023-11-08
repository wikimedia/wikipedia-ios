import UIKit

class WelcomePanelViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var containerView: UIView!

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var scrollViewGradientView: ScrollViewGradientView!

    @IBOutlet private weak var actionLabel: UILabel!
    @IBOutlet private weak var actionButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet private weak var actionStackViewBottomConstraint: NSLayoutConstraint!

    private let titleLabelText: String
    private let actionLabelText: String?
    private let actionButtonTitle: String?
    private let contentViewController: UIViewController & Themeable

    private var theme = Theme.standard

    init(titleLabelText: String, actionLabelText: String?, actionButtonTitle: String?, contentViewController: UIViewController & Themeable) {
        self.titleLabelText = titleLabelText
        self.actionLabelText = actionLabelText
        self.actionButtonTitle = actionButtonTitle
        self.contentViewController = contentViewController
        super.init(nibName: "WelcomePanelViewController", bundle: Bundle.main)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitleLabel()
        configureActionLabel()
        configureActionButton()
        addContentViewController()
        apply(theme: theme)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scrollView.contentSizeHeightExceedsBoundsHeight() {
            scrollView.flashVerticalScrollIndicatorAfterDelay(1.5)
        }
    }

    // MARK: Configuration

    private func configureActionButton() {
        actionButton.setTitle(actionButtonTitle, for: .normal)
        actionButton.isHidden = actionButtonTitle == nil
        actionStackViewBottomConstraint.constant = actionButton.isHidden ? 21 : 0
    }

    private func configureTitleLabel() {
        titleLabel.text = titleLabelText
    }

    private func configureActionLabel() {
        actionLabel.text = actionLabelText
        actionLabel.isHidden = actionLabelText == nil
    }

    private func addContentViewController() {
        addChild(contentViewController, to: containerView)
    }

    private func addChild(_ viewController: (UIViewController & Themeable)?, to view: UIView) {
        guard
            let viewController = viewController,
            viewController.parent == nil,
            viewIfLoaded != nil
            else {
                return
        }
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(viewController.view)
        viewController.didMove(toParent: self)
        viewController.apply(theme: theme)
    }

    @IBAction private func performAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension WelcomePanelViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        contentViewController.apply(theme: theme)
        scrollViewGradientView.apply(theme: theme)
        titleLabel.backgroundColor = theme.colors.midBackground
        titleLabel.textColor = theme.colors.primaryText
        actionLabel.textColor = theme.colors.accent
        actionLabel.backgroundColor = theme.colors.midBackground
        actionButton.backgroundColor = theme.colors.link
    }
}

private extension UIScrollView {
    func contentSizeHeightExceedsBoundsHeight() -> Bool {
        return contentSize.height - bounds.size.height > 0
    }
    func flashVerticalScrollIndicatorAfterDelay(_ delay: TimeInterval) {
        dispatchOnMainQueueAfterDelayInSeconds(delay) {
            self.flashScrollIndicators()
        }
    }
}
