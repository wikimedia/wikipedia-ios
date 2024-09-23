import WMFComponents

class ShareAFactViewController: UIViewController {

    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var articleLicenseView: LicenseView!
    @IBOutlet weak var imageLicenseView: LicenseView!
    @IBOutlet weak var imageGradientView: WMFGradientView!

    @IBOutlet weak var imageWordmarkView: UIImageView!
    @IBOutlet weak var imageMadeWithLabel: UILabel!
    
    @IBOutlet weak var textWordmarkView: UIImageView!
    @IBOutlet weak var textMadeWithLabel: UILabel!
    
    @IBOutlet weak var articleTitleTrailingToTextWordmarkConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var imageMadeWithLabelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var imageViewLetterboxConstraints: [NSLayoutConstraint]!
    
    override func viewDidLoad() {
        let theme = Theme.standard // always use the standard theme for now
        view.backgroundColor = theme.colors.paperBackground
        articleTitleLabel.textColor = theme.colors.primaryText
        separatorView.backgroundColor = theme.colors.border
        textLabel.textColor = theme.colors.primaryText
        articleLicenseView.tintColor = theme.colors.secondaryText
        imageLicenseView.tintColor = .white
        
        textMadeWithLabel.text = WMFLocalizedString("share-a-fact-made-with", value: "Made with the Wikipedia app", comment: "Indicates that the share-a-fact card was made with the Wikipedia app")
        imageMadeWithLabel.text = textMadeWithLabel.text
        
        imageGradientView.gradientLayer.colors = [UIColor.clear.cgColor, UIColor(white: 0, alpha: 0.1).cgColor, UIColor(white: 0, alpha: 0.4).cgColor]
        imageGradientView.gradientLayer.locations = [NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
        imageGradientView.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        imageGradientView.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    public func update(with articleURL: URL, articleTitle: String?, text: String?, image: UIImage?, imageLicense: MWKLicense?) {
        view.semanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: articleURL.wmf_contentLanguageCode)
        textLabel.semanticContentAttribute = view.semanticContentAttribute
        articleTitleLabel.semanticContentAttribute = view.semanticContentAttribute
        imageContainerView.semanticContentAttribute = view.semanticContentAttribute
        imageLicenseView.semanticContentAttribute = view.semanticContentAttribute
        articleLicenseView.semanticContentAttribute = view.semanticContentAttribute
        let text = text ?? ""
        imageView.image = image
        isImageViewHidden = image == nil
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7
        textLabel.attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        textLabel.font = WMFFont.for(.title3)
        let width = isImageViewHidden ? view.bounds.size.width : round(0.5 * view.bounds.size.width)
        let size = textLabel.sizeThatFits(CGSize(width: width, height: view.bounds.size.height))
        if size.height > 0.6 * view.bounds.size.height {
            textLabel.font = WMFFont.for(.callout)
            textLabel.attributedText = nil // without this line, the ellipsis wasn't being added at the end of the truncated text
            textLabel.text = text
        }
        articleTitleLabel.text = articleTitle
        
        let codes: [String] = imageLicense?.code?.lowercased().components(separatedBy: "-") ?? []

        if codes.isEmpty {
            imageLicenseView.licenseCodes = ["generic"]
            if let shortDescription = imageLicense?.shortDescription {
                let label = UILabel()
                label.font = imageMadeWithLabel.font
                label.textColor = imageMadeWithLabel.textColor
                label.text = " " + shortDescription + " "
                imageLicenseView.addArrangedSubview(label)
            }
        } else {
            imageLicenseView.licenseCodes = codes
        }
        
        imageLicenseView.spacing = 0
        articleLicenseView.licenseCodes = ["cc", "by", "sa"]
        articleLicenseView.spacing = 0

        guard let image = image else {
            return
        }
        
        guard image.size.width > image.size.height else {
            return
        }

        let aspect = image.size.height / image.size.width
        let height = round(imageViewWidthConstraint.constant * aspect)
        let remainder = round(0.5 * (view.bounds.size.height - height))
        
        guard remainder > ((view.bounds.size.height - imageWordmarkView.frame.origin.y) + imageMadeWithLabelBottomConstraint.constant) else {
            return
        }
        
        backgroundImageView.image = image
        for letterboxConstraint in imageViewLetterboxConstraints {
            letterboxConstraint.constant = remainder
        }
    }
    
    var isImageViewHidden: Bool = false {
        didSet {
            imageViewTrailingConstraint.constant = isImageViewHidden ? imageViewWidthConstraint.constant : 0
            articleTitleTrailingToTextWordmarkConstraint.isActive = !isImageViewHidden
            textWordmarkView.isHidden = !isImageViewHidden
            textMadeWithLabel.isHidden = !isImageViewHidden
        }
    }


}
