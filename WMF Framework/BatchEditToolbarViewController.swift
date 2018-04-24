import UIKit

public final class BatchEditToolbarViewController: UIViewController {

    @IBOutlet weak var stackView: UIStackView?
    @IBOutlet weak var separatorView: UIView?
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
