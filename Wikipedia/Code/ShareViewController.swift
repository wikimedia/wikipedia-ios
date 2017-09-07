import UIKit

@objc(WMFShareViewController)
class ShareViewController: UIViewController, Themeable {
    @IBOutlet weak var cancelButton: UIButton!
    let text: String
    let articleTitle: String
    let articleURL: URL
    let articleImageURL: URL?
    let articleDescription: String?
    let loadGroup: DispatchGroup
    var theme: Theme
    var image: UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var busyLabel: UILabel!
    
    @objc required public init?(text: String, article: WMFArticle, theme: Theme) {
        guard let articleURL = article.url else {
            return nil
        }
        self.text = text
        self.articleTitle = article.displayTitle ?? ""
        self.articleDescription = article.capitalizedWikidataDescriptionOrSnippet
        self.articleURL = articleURL
        self.articleImageURL = article.imageURL(forWidth: 640)
        self.theme = theme
        self.loadGroup = DispatchGroup()
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
        DispatchQueue.global(qos: .background).async {
            self.loadGroup.wait()
            DispatchQueue.main.async {
                let image = self.createShareAFactCard()
                self.showActivityViewController(with: image)
            }
        }
    }
    
    func loadImage() {
        if let imageURL = self.articleImageURL {
            loadGroup.enter()
            ImageController.shared.fetchImage(withURL: imageURL, failure: { (fail) in
                self.loadGroup.leave()
            }) { (download) in
                self.image = download.image.staticImage
                self.loadGroup.leave()
            }
        }
    }
    
    func createShareAFactCard() -> UIImage? {
        let cardController = WMFShareCardViewController(nibName: "ShareCard", bundle: nil)
        let cardView = cardController.view
        cardController.fillCard(withArticleURL: articleURL, articleTitle: articleTitle, articleDescription: articleDescription, text: text, image: image)
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
        activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        present(activityVC, animated: true, completion: nil)
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
