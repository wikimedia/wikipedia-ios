class DescriptionWelcomeContentsViewController: UIViewController, Themeable {
    private var theme = Theme.standard
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        descriptionLabel.textColor = theme.colors.primaryText
    }
    
    @IBOutlet private var descriptionLabel:UILabel!
    
    var pageType:DescriptionWelcomePageType = .intro

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIStrings()
        apply(theme: theme)
        view.wmf_configureSubviewsForDynamicType()
    }
    
    private func updateUIStrings() {
        switch pageType {
        case .intro:
            descriptionLabel?.text = WMFLocalizedString("description-welcome-descriptions-sub-title", value:"Summarizes an article to help readers understand the subject at a glance", comment:"Subtitle text explaining article descriptions")
        case .exploration:
            descriptionLabel?.text = WMFLocalizedString("description-welcome-concise-sub-title", value:"Ideally one line, between two to twelve words", comment:"Subtitle text explaining descriptions should be concise")
        }
    }
}
