
class WMFWelcomeExplorationViewController: UIViewController {

    @IBOutlet fileprivate var exploreTitleLabel:UILabel!
    @IBOutlet fileprivate var exploreDescriptionLabel:UILabel!

    @IBOutlet fileprivate var placesTitleLabel:UILabel!
    @IBOutlet fileprivate var placesDescriptionLabel:UILabel!

    @IBOutlet fileprivate var onThisDayTitleLabel:UILabel!
    @IBOutlet fileprivate var onThisDayDescriptionLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        
        exploreTitleLabel.text = CommonStrings.exploreFeedTitle
        exploreDescriptionLabel.text = WMFLocalizedString("welcome-exploration-explore-feed-description", value:"Recommended reading and daily articles from our community", comment:"Description for Explore feed")

        placesTitleLabel.text = WMFLocalizedString("welcome-exploration-places-title", value:"Places tab", comment:"Title for Places")
        placesDescriptionLabel.text = WMFLocalizedString("welcome-exploration-places-description", value:"Discover landmarks near you or search for places across the world", comment:"Description for Places")

        onThisDayTitleLabel.text = WMFLocalizedString("welcome-exploration-on-this-day-title", value:"On this day", comment:"Title for On this day")
        onThisDayDescriptionLabel.text = WMFLocalizedString("welcome-exploration-on-this-day-description", value:"Travel back in time to learn what happened today in history", comment:"Description for On this day")
        
        view.wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        exploreTitleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        placesTitleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        onThisDayTitleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
    }
}
