import UIKit

public final class BatchEditToolbarViewController: UIViewController {

    public var items: [UIButton] = []
    fileprivate var theme: Theme = Theme.standard
    
    public override func didMove(toParentViewController parent: UIViewController?) {
        let stackView = UIStackView(arrangedSubviews: items)
        stackView.axis = UILayoutConstraintAxis.horizontal
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.center
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let centerXConstraint = stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let centerYConstraint = stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let widthConstraint = stackView.widthAnchor.constraint(equalTo: view.widthAnchor)
        let heightConstraint = stackView.heightAnchor.constraint(equalTo: view.heightAnchor)
        NSLayoutConstraint.activate([centerXConstraint, centerYConstraint, widthConstraint, heightConstraint])
        apply(theme: theme)
    }
    
    public func setItemsEnabled(_ enabled: Bool) {
        // do not enable the "Update" button for now
        for item in items where item.tag != 0 {
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
    }
}
