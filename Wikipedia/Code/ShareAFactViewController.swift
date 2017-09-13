import UIKit

class ShareAFactViewController: UIViewController {

    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var articleLicenseView: LicenseView!
    @IBOutlet weak var imageLicenseView: LicenseView!
    @IBOutlet weak var imageGradientView: WMFGradientView!

    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var imageViewLetterboxConstraints: [NSLayoutConstraint]!
    
    override func viewDidLoad() {
        let theme = Theme.standard //always use the standard theme for now
        view.backgroundColor = theme.colors.paperBackground
        articleTitleLabel.textColor = theme.colors.primaryText
        separatorView.backgroundColor = theme.colors.border
        textLabel.textColor = theme.colors.primaryText
        articleLicenseView.tintColor = theme.colors.secondaryText
        imageLicenseView.tintColor = .white
        imageGradientView.setStart(.clear, end: UIColor(white: 0, alpha: 0.4))
    }
    
    public func update(with articleURL: URL, articleTitle: String?, text: String?, image: UIImage?) {
        view.semanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: articleURL.wmf_language)
        textLabel.semanticContentAttribute = view.semanticContentAttribute
        imageView.image = image
        isImageViewHidden = image == nil
        textLabel.text = text
        articleTitleLabel.text = articleTitle
        imageLicenseView.licenseCodes = ["cc", "by", "sa"]
        articleLicenseView.licenseCodes = ["cc", "by", "sa"]
        
        guard let image = image else {
            return
        }
        
        guard image.size.width > image.size.height else {
            return
        }
        
        let aspect = image.size.height / image.size.width
        let height = floor(imageViewWidthConstraint.constant * aspect)
        let remainder = round(0.5 * (view.bounds.size.height - height))
        for letterboxConstraint in imageViewLetterboxConstraints {
            letterboxConstraint.constant = remainder
        }
    }
    
    var isImageViewHidden: Bool = false {
        didSet {
            imageViewTrailingConstraint.constant = isImageViewHidden ? imageViewWidthConstraint.constant : 0
        }
    }


}
