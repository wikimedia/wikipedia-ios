
class AbuseFilterAlertView: UIView, Themeable {

    @IBOutlet private var iconLabel: WikiGlyphLabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitle1Label: UILabel!
    @IBOutlet private var subtitle2Label: UILabel!
    @IBOutlet private var subtitle3Label: UILabel!
    @IBOutlet private var subtitle4Label: UILabel!
    @IBOutlet private var subtitle5Label: UILabel!
    
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
            titleLabel.text = WMFLocalizedStringWithDefaultValue("abuse-filter-disallow-heading", nil, nil, "You cannot publish this edit. Please go back and change it.", "Header text for disallowed edit warning.")
            subtitle1Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-disallow-unconstructive", nil, nil, "An automated filter has identified this edit as potentially unconstructive or a vandalism attempt.", "Label text for unconstructive edit description")
            subtitle2Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-disallow-notable", nil, nil, "Wikipedia is an encyclopedia and only neutral, notable content belongs here.", "Label text for notable content description")
            subtitle3Label.text = nil
            subtitle4Label.text = nil
            subtitle5Label.text = nil
        case .warning:
            titleLabel.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-heading", nil, nil, "This looks like an unconstructive edit, are you sure you want to publish it?", "Header text for unconstructive edit warning")
            subtitle1Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-subheading", nil, nil, "Your edit may contain one or more of the following:", "Subheading text for potentially unconstructive edit warning")
            subtitle2Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-caps", nil, nil, "Typing in ALL CAPS", "Label text for typing in all capitals")
            subtitle3Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-blanking", nil, nil, "Blanking articles or spamming", "Label text for blanking articles or spamming")
            subtitle4Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-irrelevant", nil, nil, "Irrelevant external links or images", "Label text for irrelevant external links and images")
            subtitle5Label.text = WMFLocalizedStringWithDefaultValue("abuse-filter-warning-repeat", nil, nil, "Repeeeeating characters", "Label text for repeating characters")
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        subtitle1Label.textColor = theme.colors.secondaryText
        subtitle2Label.textColor = theme.colors.secondaryText
        subtitle3Label.textColor = theme.colors.secondaryText
        subtitle4Label.textColor = theme.colors.secondaryText
        subtitle5Label.textColor = theme.colors.secondaryText
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
