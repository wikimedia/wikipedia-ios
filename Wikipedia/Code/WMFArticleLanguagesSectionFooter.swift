class WMFArticleLanguagesSectionFooter : UITableViewHeaderFooterView, Themeable {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = UIView.init(frame: bounds)
        addButton.setTitle(WMFLocalizedString("welcome-languages-add-button", value:"Add another language", comment:"Title for button for adding another language"), for: .normal)
        titleLabel.text = WMFLocalizedString("settings-primary-language-details", value:"The first language in this list is used as the primary language for the app. Changing this language will change daily content (such as Featured Article) shown on Explore.", comment:"Explanation of how the first preferred language is used. \"Explore\" is {{msg-wm|Wikipedia-ios-home-title}}.")
        wmf_configureSubviewsForDynamicType()
        apply(theme: .standard)
    }
    func apply(theme: Theme) {
        backgroundView?.backgroundColor = theme.colors.baseBackground
        titleLabel.textColor = theme.colors.secondaryText
        addButton.setTitleColor(theme.colors.link, for: .normal)
    }
}
