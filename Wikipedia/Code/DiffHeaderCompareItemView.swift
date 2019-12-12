
import UIKit

class DiffHeaderCompareItemView: UIView {

    @IBOutlet var userStackView: UIStackView!
    @IBOutlet var headingAndTimestampStackView: UIStackView!
    @IBOutlet var userAndSummaryStackView: UIStackView!
    @IBOutlet var containerStackView: UIStackView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    @IBOutlet var userIconImageView: UIImageView!
    @IBOutlet var stackViewTopPaddingConstraint: NSLayoutConstraint!
    let squishedBottomPadding: CGFloat = 4
    let maxStackViewTopPadding: CGFloat = 14
    let minStackViewTopPadding: CGFloat = 6
    let maxContainerStackViewSpacing: CGFloat = 10
    let minContainerStackViewSpacing: CGFloat = 4
    var minHeight: CGFloat {
        return timestampLabel.frame.maxY + stackViewTopPaddingConstraint.constant + squishedBottomPadding
    }
    private var viewModel: DiffHeaderCompareItemViewModel?
    
    private var userAndSummaryTapGestureRecognizer: UITapGestureRecognizer?
    private var headingAndTimestampTapGestureRecognizer:  UITapGestureRecognizer?
    weak var delegate: DiffHeaderActionDelegate?

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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let userAndSummaryTapGestureRecognizer = userAndSummaryTapGestureRecognizer {
            userAndSummaryStackView.addGestureRecognizer(userAndSummaryTapGestureRecognizer)
        }
        
        if let headingAndTimestampTapGestureRecognizer = headingAndTimestampTapGestureRecognizer {
            headingAndTimestampStackView.addGestureRecognizer(headingAndTimestampTapGestureRecognizer)
        }
    }
    
    func update(_ viewModel: DiffHeaderCompareItemViewModel) {

        headingLabel.text = viewModel.heading
        timestampLabel.text = viewModel.timestampString
        userIconImageView.image = UIImage(named: "user-edit")
        usernameLabel.text = viewModel.username
        
        if viewModel.isMinor,
            let minorImage = UIImage(named: "minor-edit") {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = minorImage
            let attributedText = NSMutableAttributedString(attachment: imageAttachment)
            attributedText.addAttributes([NSAttributedString.Key.baselineOffset: -1], range: NSRange(location: 0, length: 1))
            
            if let summary = viewModel.summary {
                attributedText.append(NSAttributedString(string: "  \(summary)"))
            }
            
            summaryLabel.attributedText = attributedText
        } else {
            summaryLabel.text = viewModel.summary
        }
        
        updateFonts(with: traitCollection)

        self.viewModel = viewModel
        updateAccessibilityLabels(viewModel: viewModel)
    }
    
    func updateAccessibilityLabels(viewModel: DiffHeaderCompareItemViewModel) {
        let isMinorAccessibilityString = viewModel.isMinor ? CommonStrings.minorEditTitle : ""
        let authorString = String.localizedStringWithFormat(CommonStrings.authorTitle, viewModel.username ?? CommonStrings.unknownTitle)
        headingAndTimestampStackView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [headingLabel.text, timestampLabel.text])
        userAndSummaryStackView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [authorString, isMinorAccessibilityString, summaryLabel.text])
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }

        let userStackViewConvertedPoint = self.convert(point, to: userStackView)
        if userStackView.point(inside: userStackViewConvertedPoint, with: event) {
            return true
        }
        
        let timestampLabelConvertedPoint = self.convert(point, to: timestampLabel)
        if timestampLabel.point(inside: timestampLabelConvertedPoint, with: event) {
            return true
        }
        
        return false
    }
    
    @objc func tappedElementWithSender(_ sender: UITapGestureRecognizer) {
        if let username = viewModel?.username,
            sender == userAndSummaryTapGestureRecognizer {
            delegate?.tappedUsername(username: username)
        } else if let revisionID = viewModel?.revisionID,
            sender == headingAndTimestampTapGestureRecognizer {
            delegate?.tappedRevision(revisionID: revisionID)
        }
    }
}

private extension DiffHeaderCompareItemView {
    
    func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderCompareItemView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        userAndSummaryTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedElementWithSender))
        headingAndTimestampTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedElementWithSender))
        headingAndTimestampStackView.isAccessibilityElement = true
        userAndSummaryStackView.isAccessibilityElement = true
        headingAndTimestampStackView.accessibilityTraits = [.link]
        userAndSummaryStackView.accessibilityTraits = [.link]
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        timestampLabel.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        usernameLabel.font = UIFont.wmf_font(DynamicTextStyle.mediumCaption1, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(DynamicTextStyle.italicCaption1, compatibleWithTraitCollection: traitCollection)
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
