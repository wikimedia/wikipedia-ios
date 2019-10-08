
import UIKit

class DiffHeaderSummaryView: UIView {
    
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
        tagLabel.text = "m" //TONITODO: tags
        summaryLabel.text = viewModel.summary
        updateFonts(with: traitCollection)
        
        //theming
        backgroundColor = viewModel.theme.colors.paperBackground
        contentView.backgroundColor = viewModel.theme.colors.paperBackground
        headingLabel.textColor = viewModel.theme.colors.secondaryText
        tagLabel.textColor = viewModel.theme.colors.primaryText
        summaryLabel.textColor = viewModel.theme.colors.primaryText
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
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
        headingLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        tagLabel.font = UIFont.wmf_font(DynamicTextStyle.boldSubheadline, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(DynamicTextStyle.italicCallout, compatibleWithTraitCollection: traitCollection)
    }
}
