
import UIKit

class DiffHeaderCompareItemView: UIView {

    @IBOutlet var containerStackView: UIStackView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var tagLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    @IBOutlet var userIconImageView: UIImageView!
    @IBOutlet var stackViewTopPaddingConstraint: NSLayoutConstraint!
    let squishedBottomPadding: CGFloat = 5.5
    let maxStackViewTopPadding: CGFloat = 14
    let minStackViewTopPadding: CGFloat = 6
    let maxContainerStackViewSpacing: CGFloat = 10
    let minContainerStackViewSpacing: CGFloat = 4
    var minHeight: CGFloat {
        return timestampLabel.frame.maxY + stackViewTopPaddingConstraint.constant + squishedBottomPadding
    }
    private var viewModel: DiffHeaderCompareItemViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
        stackViewTopPaddingConstraint.constant = maxStackViewTopPadding
        containerStackView.spacing = maxContainerStackViewSpacing
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func update(_ viewModel: DiffHeaderCompareItemViewModel) {

        headingLabel.text = viewModel.heading
        timestampLabel.text = viewModel.timestampString
        if #available(iOS 13.0, *) {
            userIconImageView.image = UIImage(systemName: "person.fill")
        } else {
            userIconImageView.isHidden = true //TONITODO: get asset for this
        }
        usernameLabel.text = viewModel.username
        //tagsLabel.text = "m" //TONITODO: tags
        tagLabel.isHidden = true
        summaryLabel.text = viewModel.summary //TONITODO: italic for some of this
        
        updateFonts(with: traitCollection)

        self.viewModel = viewModel
    }
    
    func squish(by percentage: CGFloat) {
        let topPaddingDelta = maxStackViewTopPadding - minStackViewTopPadding
        stackViewTopPaddingConstraint.constant = maxStackViewTopPadding - (topPaddingDelta * percentage)
        
        let spacingDelta = maxContainerStackViewSpacing - minContainerStackViewSpacing
        containerStackView.spacing = maxContainerStackViewSpacing - (spacingDelta * percentage)

        //tonitodo: shrink font size
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
}

private extension DiffHeaderCompareItemView {
    
    func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderCompareItemView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        timestampLabel.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        usernameLabel.font = UIFont.wmf_font(DynamicTextStyle.mediumCaption1, compatibleWithTraitCollection: traitCollection)
        tagLabel.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(DynamicTextStyle.caption1, compatibleWithTraitCollection: traitCollection) //tonitodo: italic attributed string?
    }
}

extension DiffHeaderCompareItemView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        
        if let viewModel = viewModel {
            timestampLabel.textColor = viewModel.accentColor
            usernameLabel.textColor = viewModel.accentColor
            userIconImageView.tintColor = viewModel.accentColor
        }
    }
}
