import UIKit


protocol ArticlePopoverViewControllerDelegate: NSObjectProtocol {
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction: WMFArticleAction)
}

class ArticlePopoverViewController: UIViewController {

    weak var delegate: ArticlePopoverViewControllerDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var buttonStackView: UIStackView!
    
    @IBOutlet weak var saveButton: SaveButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
    @IBOutlet weak var articleSummaryView: UIView!
    
    let article: WMFArticle
    
    var showSaveAndShareTitles = true
    
    required init(_ article: WMFArticle) {
        self.article = article
        super.init(nibName: "ArticlePopoverViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        articleSummaryView.addGestureRecognizer(tapGR)
        
        shareButton.setTitle(WMFLocalizedString("action-share", value:"Share", comment:"Title for the 'Share' action\n{{Identical|Share}}"), for: .normal)
        shareButton.setImage(#imageLiteral(resourceName: "places-share"), for: .normal)
        
        readButton.setTitle(WMFLocalizedString("action-read", value:"Read", comment:"Title for the 'Read' action\n{{Identical|Read}}"), for: .normal)
        readButton.setImage(#imageLiteral(resourceName: "places-more"), for: .normal)
        
        updateSaveButtonTitle()
        
        // Verify that the localized titles for save, share, and read will fit
        let sizeToFit = buttonStackView.bounds.size
        let widthToCheck = 0.33*sizeToFit.width
        let shareButtonSize = shareButton.sizeThatFits(sizeToFit)
        let saveButtonSize = saveButton.sizeThatFits(sizeToFit)
        let readButtonSize = readButton.sizeThatFits(sizeToFit)
        // If any of the the titles don't fit, fill proportionally and remove the titles for share and save
        showSaveAndShareTitles = shareButtonSize.width < widthToCheck && saveButtonSize.width < widthToCheck && readButtonSize.width < widthToCheck
        if !showSaveAndShareTitles {
            shareButton.setTitle(nil, for: .normal)
            saveButton.setTitle(nil, for: .normal)
            buttonStackView.distribution = .fillProportionally
        }
        
        titleLabel.text = article.displayTitle
        subtitleLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        
        view.wmf_configureSubviewsForDynamicType()
    }
    
    func updateSaveButtonTitle() {
        guard showSaveAndShareTitles else {
            return
        }
        saveButton.saveButtonState = article.savedDate == nil ? .shortSave : .shortSaved
    }
    
    func configureView(withTraitCollection traitCollection: UITraitCollection) {
        let titleLabelFont = UIFont.wmf_preferredFontForFontFamily(.georgia, withTextStyle: .title3, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = titleLabelFont
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureView(withTraitCollection: traitCollection)
    }
    
    func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        switch tapGR.state {
        case .recognized:
            delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .read)
        default:
            break
        }
    }
    
    @IBAction func save(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .save)
        updateSaveButtonTitle()
    }
    
    @IBAction func share(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .share)
    }
    
    @IBAction func read(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .read)
    }
    
}


