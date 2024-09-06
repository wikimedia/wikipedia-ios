import WMFComponents

final class InsertMediaLabelTableFooterView: SetupView, Themeable {
    private let label = UILabel()
    private let separator = UIView()

    init(text: String) {
        label.text = text
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        let separatorLeadingConstraint = separator.leadingAnchor.constraint(equalTo: leadingAnchor)
        let separatorTrailingConstraint = separator.trailingAnchor.constraint(equalTo: trailingAnchor)
        let separatorTopConstraint = separator.topAnchor.constraint(equalTo: topAnchor)
        let separatorHeightConstraint = separator.heightAnchor.constraint(equalToConstant: 0.5)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        let labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15)
        let labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15)
        let labelBottomConstraint = label.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 15)
        let labelTopConstraint = label.topAnchor.constraint(equalTo: topAnchor, constant: 5)
        NSLayoutConstraint.activate([separatorLeadingConstraint, separatorTrailingConstraint, separatorTopConstraint, separatorHeightConstraint, labelLeadingConstraint, labelTrailingConstraint, labelBottomConstraint, labelTopConstraint])
        updateFonts()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        label.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        label.backgroundColor = backgroundColor
        label.textColor = theme.colors.secondaryText
        separator.backgroundColor = theme.colors.border
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.preferredMaxLayoutWidth = label.bounds.width
    }
}
