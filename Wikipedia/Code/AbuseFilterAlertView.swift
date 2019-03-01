
enum AbuseFilterAlertType {
    case warning
    case disallow
    func image() -> UIImage? {
        switch self {
        case .warning:
            return #imageLiteral(resourceName: "abuse-filter-flag")
        case .disallow:
            return #imageLiteral(resourceName: "abuse-filter-alert")
        }
    }
}

class AbuseFilterAlertView: UIView, Themeable {

    @IBOutlet private var iconImageView: UIImageView!
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
            iconImageView.image = type.image()
            configureLabels(for: type)
        }
    }

    private func configureLabels(for type: AbuseFilterAlertType) {
        switch type {
        case .disallow:
            titleLabel.text = WMFLocalizedString("abuse-filter-disallow-heading", value: "You cannot publish this edit", comment: "Header text for disallowed edit warning.")
            subtitleLabel.text = nil
            detailsLabel1.text = WMFLocalizedString("abuse-filter-disallow-unconstructive", value: "An automated filter has identified this edit as potentially unconstructive or as a vandalism attempt. Please go back and change your edit.", comment: "Label text for unconstructive edit description")
            detailsLabel2.text = nil
            detailsLabel3.text = nil
            detailsLabel4.text = nil
            detailsLabel5.text = nil
        case .warning:
            titleLabel.text = WMFLocalizedString("abuse-filter-warning-heading", value: "This looks like an unconstructive edit, are you sure you want to publish it?", comment: "Header text for unconstructive edit warning")
            subtitleLabel.text = WMFLocalizedString("abuse-filter-warning-subheading", value: "Your edit may contain:", comment: "Subheading text for potentially unconstructive edit warning")
            detailsLabel1.text = WMFLocalizedString("abuse-filter-warning-caps", value: "All caps text", comment: "Label text for typing in all capitals")
            detailsLabel2.text = WMFLocalizedString("abuse-filter-warning-blanking", value: "Deleting sections or full articles", comment: "Label text for blanking sections or articles")
            detailsLabel3.text = WMFLocalizedString("abuse-filter-warning-spam", value: "Adding spam to articles", comment: "Label text for adding spam to articles")
            detailsLabel4.text = WMFLocalizedString("abuse-filter-warning-irrelevant", value: "Irrelevant external links or images", comment: "Label text for irrelevant external links and images")
            detailsLabel5.text = WMFLocalizedString("abuse-filter-warning-repeat", value: "Repeating characters", comment: "Label text for repeating characters")
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
