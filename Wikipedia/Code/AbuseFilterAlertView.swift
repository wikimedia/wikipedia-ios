
enum AbuseFilterAlertType {
    case warning
    case disallow
}

class AbuseFilterAlertView: UIView, Themeable {

    @IBOutlet private var iconLabel: WikiGlyphLabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var detailsLabel1: UILabel!
    @IBOutlet private var detailsLabel2: UILabel!
    @IBOutlet private var detailsLabel3: UILabel!
    @IBOutlet private var detailsLabel4: UILabel!
    @IBOutlet private var detailsLabel5: UILabel!

    public var theme: Theme = .standard

    public var type: AbuseFilterAlertType = .disallow {
        didSet {
            iconLabel.configureAsIcon(for: type)
            configureLabels(for: type)
        }
    }

    private func configureLabels(for type: AbuseFilterAlertType) {
        switch type {
        case .disallow:
            titleLabel.text = WMFLocalizedStringWithDefaultValue("abuse-filter-disallow-heading", nil, nil, "You cannot publish this edit", "Header text for disallowed edit warning.")
            subtitleLabel.text = nil
            detailsLabel1.text = WMFLocalizedStringWithDefaultValue("abuse-filter-disallow-unconstructive", nil, nil, "An automated filter has identified this edit as potentially unconstructive or as a vandalism attempt. Please go back and change your edit.", "Label text for unconstructive edit description")
            detailsLabel2.text = nil
            detailsLabel3.text = nil
            detailsLabel4.text = nil
            detailsLabel5.text = nil
        case .warning:
            titleLabel.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-heading", nil, nil, "This looks like an unconstructive edit, are you sure you want to publish it?", "Header text for unconstructive edit warning")
            subtitleLabel.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-subheading", nil, nil, "Your edit may contain:", "Subheading text for potentially unconstructive edit warning")
            detailsLabel1.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-caps", nil, nil, "All caps text", "Label text for typing in all capitals")
            detailsLabel2.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-blanking", nil, nil, "Deleting sections or full articles", "Label text for blanking sections or articles")
            detailsLabel3.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-spam", nil, nil, "Adding spam to articles", "Label text for adding spam to articles")
            detailsLabel4.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-irrelevant", nil, nil, "Irrelevant external links or images", "Label text for irrelevant external links and images")
            detailsLabel5.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-repeat", nil, nil, "Repeating characters", "Label text for repeating characters")
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = (type == .disallow) ? theme.colors.error : theme.colors.warning
        subtitleLabel.textColor = theme.colors.secondaryText
        detailsLabel1.textColor = theme.colors.secondaryText
        detailsLabel2.textColor = theme.colors.secondaryText
        detailsLabel3.textColor = theme.colors.secondaryText
        detailsLabel4.textColor = theme.colors.secondaryText
        detailsLabel5.textColor = theme.colors.secondaryText
    }
}

private extension WikiGlyphLabel {
    func configureAsIcon(for type: AbuseFilterAlertType) {
        let string = (type == .disallow) ? WIKIGLYPH_X : WIKIGLYPH_FLAG
        let bgColor:UIColor = (type == .disallow) ? .wmf_red : .wmf_orange
        let fontSize: CGFloat = (type == .disallow) ? 74.0 : 70.0
        let baselineOffset: CGFloat = (type == .disallow) ? 8.4 : 5.5
        setWikiText(string, color: .white, size: fontSize, baselineOffset: baselineOffset)
        layer.cornerRadius = frame.size.width / 2.0
        layer.masksToBounds = true
        backgroundColor = bgColor
    }
}
