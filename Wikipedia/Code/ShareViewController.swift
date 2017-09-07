import UIKit

@objc(WMFShareViewController)
class ShareViewController: UIViewController, Themeable {
    @IBOutlet weak var cancelButton: UIButton!
    let text: String
    let article: WMFArticle
    var theme: Theme
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var busyView: UIView!
    @IBOutlet weak var busyLabel: UILabel!
    
    @objc required public init(text: String, article: WMFArticle, theme: Theme) {
        self.text = text
        self.article = article
        self.theme = theme
        super.init(nibName: "ShareViewController", bundle: nil)
        modalPresentationStyle = .overCurrentContext
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
