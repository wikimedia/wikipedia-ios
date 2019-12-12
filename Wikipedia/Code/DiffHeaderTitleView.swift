
import UIKit

class DiffHeaderTitleView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    
    private(set) var viewModel: DiffHeaderTitleViewModel?
    
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
        
        if let subtitle = viewModel.subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }
        
        
        updateFonts(with: traitCollection)

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }
        return false
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

extension DiffHeaderTitleView: Themeable {
    func apply(theme: Theme) {
        
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.primaryText
        
        if let subtitleColor = viewModel?.subtitleColor {
            subtitleLabel.textColor = subtitleColor
        } else {
            subtitleLabel.textColor = theme.colors.secondaryText
        }
    }
}
