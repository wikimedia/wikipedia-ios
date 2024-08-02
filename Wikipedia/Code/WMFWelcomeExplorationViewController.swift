import WMFComponents

class WMFWelcomeExplorationViewController: ThemeableViewController {

    @IBOutlet private var exploreTitleLabel:UILabel!
    @IBOutlet private var exploreDescriptionLabel:UILabel!

    @IBOutlet private var placesTitleLabel:UILabel!
    @IBOutlet private var placesDescriptionLabel:UILabel!

    @IBOutlet private var onThisDayTitleLabel:UILabel!
    @IBOutlet private var onThisDayDescriptionLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        
        exploreTitleLabel.text = CommonStrings.exploreFeedTitle
        exploreDescriptionLabel.text = WMFLocalizedString("welcome-exploration-explore-feed-description", value:"Recommended reading and daily articles from our community", comment:"Description for Explore feed")

        placesTitleLabel.text = WMFLocalizedString("welcome-exploration-places-title", value:"Places tab", comment:"Title for Places")
        placesDescriptionLabel.text = WMFLocalizedString("welcome-exploration-places-description", value:"Discover landmarks near you or search for places across the world", comment:"Description for Places")

        onThisDayTitleLabel.text = WMFLocalizedString("welcome-exploration-on-this-day-title", value:"On this day", comment:"Title for On this day")
        onThisDayDescriptionLabel.text = WMFLocalizedString("welcome-exploration-on-this-day-description", value:"Travel back in time to learn what happened today in history", comment:"Description for On this day")
        updateFonts()
        view.wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        exploreTitleLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        placesTitleLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        onThisDayTitleLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
    }
}
