import UIKit

public final class BatchEditToolbarViewController: UIViewController {

    @IBOutlet private weak var stackView: UIStackView?
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var separatorView: UIView?
    public var items: [UIButton] = []
    private var theme: Theme = Theme.standard
    
    public func setItemsEnabled(_ enabled: Bool) {
        for item in items {
            item.isEnabled = enabled
        }
    }
    
    public func remove() {
        self.willMove(toParentViewController: nil)
        view.removeFromSuperview()
        self.removeFromParentViewController()
    }
    
    public override func didMove(toParentViewController parent: UIViewController?) {
        if #available(iOS 11.0, *) {
            if let parent = parent, let safeAreaOwningView = view.safeAreaLayoutGuide.owningView {
                bottomConstraint.constant = max(0, parent.bottomLayoutGuide.length - safeAreaOwningView.frame.height)
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        for item in items {
            stackView?.addArrangedSubview(item)
        }
        apply(theme: theme)
    }
}

extension BatchEditToolbarViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.midBackground
        separatorView?.backgroundColor = theme.colors.border
    }
}
