import UIKit

class ShareAFactViewController: UIViewController {

    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var onWikiLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        let theme = Theme.standard //always use the standard theme for now
        view.backgroundColor = theme.colors.paperBackground
        articleTitleLabel.textColor = theme.colors.primaryText
        onWikiLabel.textColor = theme.colors.secondaryText
        separatorView.backgroundColor = theme.colors.border
        textLabel.textColor = theme.colors.primaryText
    }
    
    public func update(with articleURL: URL, articleTitle: String?, articleDescription: String?, text: String?, image: UIImage?) {
        view.semanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleURL.wmf_language)
        imageView.image = image
        articleTitleLabel.text = articleTitle
        textLabel.text = text
    }


}
