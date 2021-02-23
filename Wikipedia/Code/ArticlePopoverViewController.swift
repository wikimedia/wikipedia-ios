import UIKit
import WMF

protocol ArticlePopoverViewControllerDelegate: NSObjectProtocol {
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction: WMFArticleAction)
}

class ArticlePopoverViewController: UIViewController {
    fileprivate static let readActionString = CommonStrings.shortReadTitle
    fileprivate static let shareActionString = CommonStrings.shortShareTitle
    
    weak var delegate: ArticlePopoverViewControllerDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var buttonStackView: UIStackView!
    
    @IBOutlet weak var saveButton: SaveButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
    @IBOutlet weak var articleSummaryView: UIView!
    @IBOutlet weak var buttonContainerView: UIView!
    
    var displayTitleHTML: String = ""
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

        shareButton.setTitle(ArticlePopoverViewController.shareActionString, for: .normal)
        shareButton.setImage(#imageLiteral(resourceName: "places-share"), for: .normal)
        
        readButton.setTitle(ArticlePopoverViewController.readActionString, for: .normal)
        readButton.setImage(#imageLiteral(resourceName: "places-more"), for: .normal)
        
        // Verify that the localized titles for save, share, and read will fit
        let sizeToFit = buttonStackView.bounds.size
        let widthToCheck = 0.33*sizeToFit.width
        let shareButtonSize = shareButton.sizeThatFits(sizeToFit)
        let saveButtonSize = saveButton.sizeThatFits(sizeToFit)
        let readButtonSize = readButton.sizeThatFits(sizeToFit)
        // If any of the titles don't fit, fill proportionally and remove the titles for share and save
        showSaveAndShareTitles = shareButtonSize.width < widthToCheck && saveButtonSize.width < widthToCheck && readButtonSize.width < widthToCheck
        if !showSaveAndShareTitles {
            shareButton.setTitle(nil, for: .normal)
            shareButton.imageEdgeInsets = .zero
            saveButton.setTitle(nil, for: .normal)
            buttonStackView.distribution = .fillProportionally
        }
        
        displayTitleHTML = article.displayTitleHTML
        subtitleLabel.text = article.capitalizedWikidataDescriptionOrSnippet
        configureView(withTraitCollection: traitCollection)
        view.wmf_configureSubviewsForDynamicType()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateMoreButtonImage(with: traitCollection)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updateMoreButtonImage(with: newCollection)
    }
    
    func updateMoreButtonImage(with traitCollection: UITraitCollection) {
        var moreImage = #imageLiteral(resourceName: "places-more")
        if traitCollection.layoutDirection == .rightToLeft {
            moreImage = moreImage.withHorizontallyFlippedOrientation()
        }
        readButton.setImage(moreImage, for: .normal)
    }
    
    public func update() {
        saveButton.showTitle = showSaveAndShareTitles
        saveButton.saveButtonState = article.isAnyVariantSaved ? .shortSaved : .shortSave
        if !saveButton.showTitle {
            saveButton.imageEdgeInsets = .zero
        }

        let saveTitle = article.isAnyVariantSaved ? CommonStrings.shortUnsaveTitle : CommonStrings.shortSaveTitle
        let saveAction = UIAccessibilityCustomAction(name: saveTitle, target: self, selector: #selector(save))
        let shareAction = UIAccessibilityCustomAction(name: ArticlePopoverViewController.shareActionString, target: self, selector: #selector(share))
        
        var accessibilityTitles = [String]()
        
        if let title = article.displayTitle {
            accessibilityTitles.append(title)
        }
        
        if let description = article.wikidataDescription {
            accessibilityTitles.append(description)
        }
        
        if let distance = descriptionLabel.text {
            accessibilityTitles.append(distance)
        }
        
        let customElement = UIAccessibilityElement(accessibilityContainer: view as Any)
        if let screenCoordinateSpace = view.window?.screen.coordinateSpace {
            customElement.accessibilityFrame = view.convert(view.bounds, to: screenCoordinateSpace)
        } else {
            customElement.accessibilityFrame = view.convert(view.bounds, to: nil)
        }
        customElement.accessibilityLabel = accessibilityTitles.joined(separator: "\n")
        customElement.accessibilityCustomActions = [saveAction, shareAction]
        customElement.accessibilityTraits = UIAccessibilityTraits.link
        view.accessibilityElements = [customElement]
    }
    
    func configureView(withTraitCollection traitCollection: UITraitCollection) {
        titleLabel.attributedText = displayTitleHTML.byAttributingHTML(with: .georgiaTitle3, matching: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureView(withTraitCollection: traitCollection)
    }
    
    @objc func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        switch tapGR.state {
        case .recognized:
            delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .read)
        default:
            break
        }
    }
    
    @IBAction func save(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .save)
        update()
    }
    
    @IBAction func share(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .share)
    }
    
    @IBAction func read(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .read)
    }
    
}


extension ArticlePopoverViewController: Themeable {
    func apply(theme: Theme) {
        view.tintColor = theme.colors.link
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.tertiaryText
        articleSummaryView.backgroundColor = theme.colors.popoverBackground
        buttonContainerView.backgroundColor = theme.colors.border
        saveButton.backgroundColor = theme.colors.popoverBackground
        shareButton.backgroundColor = theme.colors.popoverBackground
        readButton.backgroundColor = theme.colors.popoverBackground
    }
}

