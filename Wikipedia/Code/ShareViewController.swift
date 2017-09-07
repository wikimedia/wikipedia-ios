import UIKit

@objc(WMFShareViewController)
class ShareViewController: UIViewController, Themeable {
    @IBOutlet weak var cancelButton: UIButton!
    let text: String
    let article: WMFArticle
    let loadGroup: DispatchGroup
    var theme: Theme
    var image: UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var busyLabel: UILabel!
    
    @objc required public init(text: String, article: WMFArticle, theme: Theme) {
        self.text = text
        self.article = article
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
                self.createShareAFactCard(completion: { (image) in
                    self.showActivityViewController(with: image)
                })
            }
        }
    }
    
    func loadImage() {
        if let imageURL = article.imageURL(forWidth: 640) {
            loadGroup.enter()
            ImageController.shared.fetchImage(withURL: imageURL, failure: { (fail) in
                self.loadGroup.leave()
            }) { (download) in
                self.image = download.image.staticImage
                self.loadGroup.leave()
            }
        }
    }
    
    func createShareAFactCard(completion: @escaping (UIImage?) -> Void) {
        let cardController = WMFShareCardViewController(nibName: "ShareCard", bundle: nil)
        let cardView = cardController.view
        cardController.fillCard(with: article, snippet: text, image: image) {
            completion(cardView?.wmf_snapshotImage())
        }
    }
    
    func showActivityViewController(with shareAFactImage: UIImage?) {
        imageView.isHidden = false
        busyView.isHidden = true
        cancelButton.isHidden = true
        var activityItems: [Any] = [text]
        if let shareAFactImage = shareAFactImage {
            imageView.image = shareAFactImage
            activityItems.append(shareAFactImage)
        }
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
        view.backgroundColor = theme.colors.overlayBackground
    }
    
}
