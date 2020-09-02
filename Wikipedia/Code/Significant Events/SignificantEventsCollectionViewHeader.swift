
import UIKit

class SignificantEventsCollectionViewHeader: UICollectionReusableView {
    @IBOutlet weak var eventsLabel: UILabel!
    @IBOutlet weak var onLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        apply(theme: Theme.standard)
        wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        onLabel.font = UIFont.wmf_font(.heavyTitle1, compatibleWithTraitCollection: traitCollection)
    }
    
    func configureFor(summaryText: String) {
    
        eventsLabel.semanticContentAttribute = semanticContentAttribute
        onLabel.semanticContentAttribute = semanticContentAttribute
        fromLabel.semanticContentAttribute = semanticContentAttribute
        
        eventsLabel.text = summaryText
        fromLabel.text = nil
        onLabel.text = nil
    }
}

extension SignificantEventsCollectionViewHeader: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        eventsLabel.textColor = theme.colors.secondaryText
        onLabel.textColor = theme.colors.primaryText
        fromLabel.textColor = theme.colors.secondaryText
    }
}
