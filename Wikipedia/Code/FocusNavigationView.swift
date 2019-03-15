import UIKit

protocol FocusNavigationViewDelegate: class {
    func focusNavigationViewDidTapClose(_ focusNavigationView: FocusNavigationView)
}

final class FocusNavigationView: UIView {

    @IBOutlet private var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    #warning("todo: accessible close btn")
    
    weak var delegate: FocusNavigationViewDelegate?
    
    func configure(text: String? = nil, traitCollection: UITraitCollection) {
        
        if let text = text {
            titleLabel.text = text
        }
        
        titleLabel.font = UIFont.wmf_font(.mediumHeadline, compatibleWithTraitCollection: traitCollection)
        titleLabelBottomConstraint.constant = traitCollection.verticalSizeClass == .compact ? 0 : 6
    }
    
    @IBAction func tappedClose() {
        delegate?.focusNavigationViewDidTapClose(self)
    }
    
}

extension FocusNavigationView: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        closeButton.tintColor = theme.colors.secondaryText
        backgroundColor = theme.colors.inputAccessoryBackground
    }
}
