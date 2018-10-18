import UIKit

open class WMFArticlePreviewViewController: UIViewController {

    public var titleTextStyle: DynamicTextStyle = .headline
    public var titleTextColor: UIColor = .black {
        didSet {
            titleLabel.textColor = titleTextColor
        }
    }
    @objc public var titleHTML: String? {
        didSet {
            updateTitle()
        }
    }
    
    private func updateTitle() {
        titleLabel.attributedText = titleHTML?.byAttributingHTML(with: titleTextStyle, matching: traitCollection)
    }
    
    @IBOutlet weak open var marginWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak open var imageView: UIImageView!
    @IBOutlet weak open var subtitleLabel: UILabel!
    @IBOutlet weak open var titleLabel: UILabel!
    @IBOutlet weak open var rankLabel: UILabel!
    @IBOutlet weak open var separatorView: UIView!
    @IBOutlet weak open var viewCountAndSparklineContainerView: UIView!
    @IBOutlet weak open var viewCountLabel: UILabel!
    @IBOutlet weak open var sparklineView: WMFSparklineView!
    
    @IBOutlet var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabelTrailingConstraint: NSLayoutConstraint!

    public required init() {
        super.init(nibName: "WMFArticlePreviewViewController", bundle: Bundle.wmf)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    open override func viewDidLoad() {
        rankLabel.textColor = .wmf_darkGray
        separatorView.backgroundColor = .wmf_darkGray
        imageView.accessibilityIgnoresInvertColors = true
    }

    open override func awakeFromNib() {
        collapseImageAndWidenLabels = true
    }
    
    private func updateFonts() {
        updateTitle()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }
    
    @objc open var collapseImageAndWidenLabels: Bool = true {
        didSet {
            imageWidthConstraint.constant = collapseImageAndWidenLabels ? 0 : 86
            titleLabelTrailingConstraint.constant = collapseImageAndWidenLabels ? 0 : 8
            self.imageView.alpha = self.collapseImageAndWidenLabels ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }
}
