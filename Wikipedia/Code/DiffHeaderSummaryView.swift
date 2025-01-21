import WMFComponents

class DiffHeaderSummaryView: SetupView, Themeable {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var summaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    override func setup() {
        super.setup()
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -15),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 15),
            topAnchor.constraint(equalTo: stackView.topAnchor, constant: -14),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 14)
        ])
        
        stackView.addArrangedSubview(headingLabel)
        stackView.addArrangedSubview(summaryLabel)
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
        headingLabel.textColor = theme.colors.secondaryText
        summaryLabel.textColor = theme.colors.primaryText
    }
}

private extension DiffHeaderSummaryView {

    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
        summaryLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }
}
