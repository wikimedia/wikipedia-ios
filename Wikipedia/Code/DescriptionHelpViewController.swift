import UIKit

class DescriptionHelpViewController: ViewController {

    @IBOutlet weak var helpScrollView: UIScrollView!

    @IBOutlet private weak var aboutTitleLabel: UILabel!
    @IBOutlet private weak var aboutDescriptionLabel: UILabel!

    @IBOutlet private weak var tipsTitleLabel: UILabel!
    @IBOutlet private weak var tipsDescriptionLabel: UILabel!
    @IBOutlet private weak var tipsForExampleLabel: UILabel!

    @IBOutlet private weak var exampleOneTitleLabel: UILabel!
    @IBOutlet private weak var exampleOneDescriptionLabel: UILabel!

    @IBOutlet private weak var exampleTwoTitleLabel: UILabel!
    @IBOutlet private weak var exampleTwoDescriptionLabel: UILabel!

    @IBOutlet private weak var moreInfoTitleLabel: UILabel!
    @IBOutlet private weak var moreInfoDescriptionLabel: UILabel!

    @IBOutlet private weak var aboutWikidataLabel: UILabel!
    @IBOutlet private weak var wikidataGuideLabel: UILabel!
    
    public override func viewDidLoad() {
        scrollView = helpScrollView
        super.viewDidLoad()
        
        title = WMFLocalizedString("description-help-title", value:"Title description help", comment:"Title for title description editing help page")
        
        aboutTitleLabel.text = WMFLocalizedString("description-help-about-title", value:"About", comment:"")
        aboutDescriptionLabel.text = WMFLocalizedString("description-help-about-description", value:"Title descriptions summarize an article to help readers understand the subject at a glance.", comment:"")
        
        tipsTitleLabel.text = WMFLocalizedString("description-help-tips-title", value:"Tips for creating descriptions", comment:"")
        tipsDescriptionLabel.text = WMFLocalizedString("description-help-tips-description", value:"Descriptions should ideally fit on one line, and are between two to twelve words long. They are not capitalized unless the first word is a proper noun.", comment:"")
        tipsForExampleLabel.text = WMFLocalizedString("description-help-tips-for-example", value:"For example:", comment:"")
        
        exampleOneTitleLabel.text = WMFLocalizedString("description-help-tips-example-title-one", value:"painting by Leonardo Da Vinci", comment:"")
        exampleOneDescriptionLabel.text = WMFLocalizedString("description-help-tips-example-description-one", value:"title description for an article about the Mona Lisa", comment:"")
        
        exampleTwoTitleLabel.text = WMFLocalizedString("description-help-tips-example-title-two", value:"Earth’s highest mountain", comment:"")
        exampleTwoDescriptionLabel.text = WMFLocalizedString("description-help-tips-example-description-two", value:"title description for an article about Mount Everest", comment:"")
        
        moreInfoTitleLabel.text = WMFLocalizedString("description-help-more-info-title", value:"More information", comment:"")
        moreInfoDescriptionLabel.text = WMFLocalizedString("description-help-more-info-description", value:"Descriptions are stored and maintained on Wikidata,  a project of the Wikimedia Foundation which provides a free, collaborative, multilingual, secondary database supporting Wikipedia and other projects.", comment:"")

        aboutWikidataLabel.text = WMFLocalizedString("description-help-about-wikidata", value:"About Wikidata", comment:"")
        wikidataGuideLabel.text = WMFLocalizedString("description-help-wikidata-guide", value:"Wikidata guide for writing descriptions", comment:"")
    }
}
