
import UIKit

class DiffHeaderSummaryView: UIView, Themeable {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var tagLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    

    func update(_ viewModel: DiffHeaderEditSummaryViewModel) {

        headingLabel.text = viewModel.heading
        
        if viewModel.isMinor {
            tagLabel.text =  "m"
            tagLabel.isHidden = false
        } else {
            tagLabel.isHidden = true
        }
        
        summaryLabel.text = viewModel.summary
        
        updateFonts(with: traitCollection)

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        tagLabel.textColor = theme.colors.primaryText
        summaryLabel.textColor = theme.colors.primaryText
    }
}

private extension DiffHeaderSummaryView {
    
    func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderSummaryView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        tagLabel.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(DynamicTextStyle.italicCaption1, compatibleWithTraitCollection: traitCollection)
    }
}
