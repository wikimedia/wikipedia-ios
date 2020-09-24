import UIKit

@objc(WMFShareViewController)
class ShareViewController: UIViewController, Themeable {
    @IBOutlet weak var cancelButton: UIButton!
    let text: String
    let articleTitle: String
    let articleURL: URL
    let articleImageURL: URL?
    let articleDescription: String?
    let loadGroup: WMFTaskGroup
    var theme: Theme
    var image: UIImage?
    var imageLicense: MWKLicense?
    // SINGLETONTODO
    let infoFetcher = MWKImageInfoFetcher(dataStore: MWKDataStore.shared())
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var busyLabel: UILabel!
    
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewVerticallyCenteredConstraint: NSLayoutConstraint!

    @objc required public init?(text: String, article: WMFArticle, theme: Theme) {
        guard let articleURL = article.url else {
            return nil
        }
        self.text = text
        self.articleTitle = article.displayTitle ?? ""
        self.articleDescription = article.capitalizedWikidataDescription
        self.articleURL = articleURL
        self.articleImageURL = article.imageURL(forWidth: 640)
        self.theme = theme
        self.loadGroup = WMFTaskGroup()
        super.init(nibName: "ShareViewController", bundle: nil)
        modalPresentationStyle = .overCurrentContext
        loadImage()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(text: "", article: WMFArticle(), theme: Theme.standard)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        busyLabel.text = WMFLocalizedString("share-building", value: "Building Share-a-fact card…", comment: "Shown while Share-a-fact card is being constructed")
        cancelButton.setTitle(WMFLocalizedString("cancel", value: "Cancel", comment: "Cancel"), for: .normal)
        apply(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadGroup.waitInBackground {
            let image = self.createShareAFactCard()
            self.showActivityViewController(with: image)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (context) in
            self.imageViewTopConstraint.isActive = true
            self.imageViewVerticallyCenteredConstraint.isActive = false
            if let presentedActivityVC = self.presentedViewController as? UIActivityViewController {
                presentedActivityVC.popoverPresentationController?.sourceRect = self.imageView.frame
            }
        }, completion: nil)
    }
    
    func loadImage() {
        if let imageURL = self.articleImageURL, let imageName = WMFParseUnescapedNormalizedImageNameFromSourceURL(imageURL), let siteURL = articleURL.wmf_site {
            loadGroup.enter()
            let filename = "File:" + imageName
            infoFetcher.fetchGalleryInfo(forImage: filename, fromSiteURL: siteURL, failure: { (error) in
                self.loadGroup.leave()
            }, success: { (info) in
                defer {
                    self.loadGroup.leave()
                }
                
                guard let imageInfo = info as? MWKImageInfo else {
                    return
                }
                
                self.imageLicense = imageInfo.license
            })
            loadGroup.enter()
            MWKDataStore.shared().cacheController.imageCache.fetchImage(withURL: imageURL, failure: { (fail) in
                self.loadGroup.leave()
            }) { (download) in
                self.image = download.image.staticImage
                self.loadGroup.leave()
            }
        }
    }
    
    func createShareAFactCard() -> UIImage? {
        let cardController = ShareAFactViewController(nibName: "ShareAFactViewController", bundle: nil)
        let cardView = cardController.view
        cardController.update(with: articleURL, articleTitle: articleTitle, text: text, image: image, imageLicense: imageLicense)
        return cardView?.wmf_snapshotImage()
    }
    
    func showActivityViewController(with shareAFactImage: UIImage?) {
        cancelButton.isEnabled = false
        imageView.image = shareAFactImage
        UIView.animate(withDuration: 0.3) {
            self.imageView.alpha = 1
            self.busyView.alpha = 0
            self.cancelButton.alpha = 0
        }
        let itemProvider = ShareAFactActivityTextItemProvider(text: text, articleTitle: articleTitle, articleURL: articleURL)
        var activityItems = [Any]()
        if let image = shareAFactImage {
            activityItems.append(ShareAFactActivityImageItemProvider(image: image))
        }
        activityItems.append(itemProvider)
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        activityVC.popoverPresentationController?.permittedArrowDirections = .up
        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline:  .now() + .milliseconds(750), execute: {
            UIView.animate(withDuration: 0.3, animations: {
                self.imageViewTopConstraint.isActive = true
                self.imageViewVerticallyCenteredConstraint.isActive = false
                self.view.layoutIfNeeded()
            }, completion: { _ in
                activityVC.popoverPresentationController?.sourceRect = self.imageView.frame
                self.present(activityVC, animated: true, completion: nil)})
        })
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        busyLabel.textColor = theme.colors.primaryText
        view.backgroundColor = theme.colors.paperBackground.withAlphaComponent(0.9)
    }
    
}
