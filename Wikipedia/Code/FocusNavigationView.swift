import UIKit

protocol FocusNavigationViewDelegate: class {
    func focusNavigationViewDidTapClose(_ focusNavigationView: FocusNavigationView)
}

final class FocusNavigationView: UIView {


    @IBOutlet var titleLabelVerticalConstraints: [NSLayoutConstraint]!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var divView: UIView!
    
    weak var delegate: FocusNavigationViewDelegate?
    
    func configure(headerText: String? = nil, headerAccessibilityText: String? = nil, closeButtonAccessibilityText: String? = nil, traitCollection: UITraitCollection) {
       
        if let headerText = headerText {
            titleLabel.text = headerText
        }
        
        if let headerAccessibilityText = headerAccessibilityText {
            titleLabel.accessibilityLabel = headerAccessibilityText
        }
        
        titleLabel.font = UIFont.wmf_font(.mediumHeadline, compatibleWithTraitCollection: traitCollection)
        
        titleLabelVerticalConstraints.forEach { (constraint) in
            constraint.constant = traitCollection.verticalSizeClass == .compact ? 5 : 15
        }
        
        if let closeButtonAccessibilityText = closeButtonAccessibilityText {
             closeButton.accessibilityLabel = closeButtonAccessibilityText
        }
    }
    
    @IBAction func tappedClose() {
        delegate?.focusNavigationViewDidTapClose(self)
    }
    
}

extension FocusNavigationView: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        closeButton.tintColor = theme.colors.secondaryText
        backgroundColor = theme.colors.paperBackground
        divView.backgroundColor = theme.colors.midBackground
    }
}
