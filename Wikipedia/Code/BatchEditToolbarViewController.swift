import UIKit

public final class BatchEditToolbarViewController: UIViewController {

    public var items: [UIButton] = []
    private var theme: Theme = Theme.standard
    private var separator: UIView?
    
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
        
        let separator = UIView()
        view.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        let separatorWidthConstraint = separator.widthAnchor.constraint(equalTo: view.widthAnchor)
        let separatorHeightConstraint = separator.heightAnchor.constraint(equalToConstant: 0.5)
        let separatorTopConstraint = separator.topAnchor.constraint(equalTo: view.topAnchor)
        let separatorLeadingConstraint = separator.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let separatorTrailingConstraint = separator.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        NSLayoutConstraint.activate([separatorWidthConstraint, separatorHeightConstraint, separatorTopConstraint, separatorLeadingConstraint, separatorTrailingConstraint])
        self.separator = separator
        
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
        separator?.backgroundColor = theme.colors.border
    }
}
