import WMFComponents

class DiffHeaderSummaryView: UIView, Themeable {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
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
        headingLabel.accessibilityLabel = viewModel.heading

        if let summary = viewModel.summary {
            if viewModel.isMinor,
               let minorImage = UIImage(named: "minor-edit") {
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = minorImage
                let attributedText = NSMutableAttributedString(attachment: imageAttachment)
                attributedText.addAttributes([NSAttributedString.Key.baselineOffset: -1], range: NSRange(location: 0, length: 1))

                attributedText.append(NSAttributedString(string: "  \(summary)"))

                summaryLabel.attributedText = attributedText
            } else {
                summaryLabel.text = viewModel.summary
            }
            summaryLabel.accessibilityLabel = summary
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

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
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
        headingLabel.font = WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
        summaryLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }
}
