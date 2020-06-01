import UIKit

open class WMFArticlePreviewViewController: ExtensionViewController {

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
        imageView.accessibilityIgnoresInvertColors = true
        updateFonts()
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
    
    public override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        titleTextColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
        rankLabel.textColor = theme.colors.secondaryText
        viewCountLabel.textColor =  theme.colors.overlayText
        viewCountAndSparklineContainerView.backgroundColor = theme.colors.overlayBackground
        separatorView.backgroundColor = theme.colors.border
        sparklineView.apply(theme: theme)
    }
}
