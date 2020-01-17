import UIKit

class DescriptionHelpViewController: ViewController {

    @IBOutlet private weak var helpScrollView: UIScrollView!

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

    @IBOutlet private var allLabels: [UILabel]!
    @IBOutlet private var headingLabels: [UILabel]!
    @IBOutlet private var italicLabels: [UILabel]!
    @IBOutlet private var exampleBackgroundViews: [UIView]!

    @IBOutlet private var imageViews: [UIImageView]!
    @IBOutlet private var dividerViews: [UIView]!
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(theme: Theme.standard)
    }
    
    public override func viewDidLoad() {
        scrollView = helpScrollView
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        title = WMFLocalizedString("description-help-title", value:"Title description help", comment:"Title for description editing help page")
        
        aboutTitleLabel.text = WMFLocalizedString("description-help-about-title", value:"About", comment:"Description editing about label text")
        aboutDescriptionLabel.text = WMFLocalizedString("description-help-about-description", value:"Title descriptions summarize an article to help readers understand the subject at a glance.", comment:"Description editing details label text")
        
        tipsTitleLabel.text = WMFLocalizedString("description-help-tips-title", value:"Tips for creating descriptions", comment:"Description editing tips label text")
        tipsDescriptionLabel.text = WMFLocalizedString("description-help-tips-description", value:"Descriptions should ideally fit on one line, and are between two to twelve words long. They are not capitalized unless the first word is a proper noun.", comment:"Description editing tips details label text")
        tipsForExampleLabel.text = WMFLocalizedString("description-help-tips-for-example", value:"For example:", comment:"Examples label text")
        
        exampleOneTitleLabel.text = WMFLocalizedString("description-help-tips-example-title-one", value:"painting by Leonardo Da Vinci", comment:"First example label text")
        exampleOneDescriptionLabel.text = WMFLocalizedString("description-help-tips-example-description-one", value:"title description for an article about the Mona Lisa", comment:"First example description text")
        
        exampleTwoTitleLabel.text = WMFLocalizedString("description-help-tips-example-title-two", value:"Earth’s highest mountain", comment:"Second example label text")
        exampleTwoDescriptionLabel.text = WMFLocalizedString("description-help-tips-example-description-two", value:"title description for an article about Mount Everest", comment:"Second example description text")
        
        moreInfoTitleLabel.text = WMFLocalizedString("description-help-more-info-title", value:"More information", comment:"Title descriptions more info heading text")
        moreInfoDescriptionLabel.text = WMFLocalizedString("description-help-more-info-description", value:"Descriptions are stored and maintained on Wikidata, a project of the Wikimedia Foundation which provides a free, collaborative, multilingual, secondary database supporting Wikipedia and other projects.", comment:"Title descriptions more info details text")

        aboutWikidataLabel.text = WMFLocalizedString("description-help-about-wikidata", value:"About Wikidata", comment:"About Wikidata label text")
        wikidataGuideLabel.text = WMFLocalizedString("description-help-wikidata-guide", value:"Wikidata guide for writing descriptions", comment:"Wikidata guide label text")
        updateFonts()
    }
    
    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.midBackground
        imageViews.forEach {
            $0.tintColor = theme.colors.primaryText
        }
        allLabels.forEach {
            $0.textColor = theme.colors.primaryText
        }
        exampleBackgroundViews.forEach {
            $0.backgroundColor = theme.colors.descriptionBackground
        }
        headingLabels.forEach {
            $0.textColor = theme.colors.secondaryText
        }
        dividerViews.forEach {
            $0.backgroundColor = theme.colors.border
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        allLabels.forEach {
            $0.set(dynamicTextStyle: .body)
        }
        headingLabels.forEach {
            $0.set(dynamicTextStyle: .headline)
        }
        italicLabels.forEach {
            $0.set(dynamicTextStyle: .italicBody)
        }
    }
    
    @IBAction func showAboutWikidataPage() {
        navigate(to: URL(string: "https://m.wikidata.org/wiki/Wikidata:Introduction"))
    }

    @IBAction func showWikidataGuidePage() {
        navigate(to: URL(string: "https://m.wikidata.org/wiki/Help:Description#Guidelines_for_descriptions_in_English"))
    }
}

private extension UILabel {
    func set(dynamicTextStyle: DynamicTextStyle) {
        font = UIFont.wmf_font(dynamicTextStyle, compatibleWithTraitCollection: traitCollection)
    }
}
