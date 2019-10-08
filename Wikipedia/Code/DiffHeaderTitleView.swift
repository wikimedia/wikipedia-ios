
import UIKit

class DiffHeaderTitleView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    
    private var viewModel: DiffHeaderTitleViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func update(_ viewModel: DiffHeaderTitleViewModel) {
        self.viewModel = viewModel
        headingLabel.text = viewModel.heading
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        updateFonts(with: traitCollection)
        
        //theming
        backgroundColor = viewModel.theme.colors.paperBackground
        contentView.backgroundColor = viewModel.theme.colors.paperBackground
        headingLabel.textColor = viewModel.theme.colors.secondaryText
        titleLabel.textColor = viewModel.theme.colors.primaryText
        if let subtitleColor = viewModel.subtitleColor {
            subtitleLabel.textColor = subtitleColor
        } else {
            subtitleLabel.textColor = viewModel.theme.colors.secondaryText
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
}

private extension DiffHeaderTitleView {
    func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderTitleView.wmf_nibName(), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        updateFonts(with: traitCollection)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(DynamicTextStyle.boldTitle1, compatibleWithTraitCollection: traitCollection)
        if let viewModel = viewModel {
            subtitleLabel.font = UIFont.wmf_font(viewModel.subtitleTextStyle, compatibleWithTraitCollection: traitCollection)
        } else {
            subtitleLabel.font = UIFont.wmf_font(DynamicTextStyle.footnote, compatibleWithTraitCollection: traitCollection)
        }
    }
}
