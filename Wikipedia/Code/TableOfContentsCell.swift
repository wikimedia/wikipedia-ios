import WMFComponents

// MARK: - Cell
class TableOfContentsCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    
    var titleIndentationLevel: Int = 0 {
        didSet {
            titleLabelTopConstraint.constant = titleIndentationLevel == 0 ? 19 : 11
            indentationConstraint.constant =  indentationWidth * CGFloat(1 + titleIndentationLevel)
            if titleIndentationLevel == 0 {
                accessibilityTraits = .header
            } else {
                accessibilityValue = String.localizedStringWithFormat(WMFLocalizedString("table-of-contents-subheading-label", value:"Subheading %1$d", comment:"VoiceOver label to indicate level of subheading in table of contents. %1$d is replaced by the level of subheading."), titleIndentationLevel)
            }
        }
    }
    
    private var titleHTML: String = ""
    private var titleTextStyle: WMFFont = .georgiaTitle3
    private var isTitleLabelHighlighted: Bool = false
    func setTitleHTML(_ html: String, with textStyle: WMFFont, highlighted: Bool, color: UIColor, selectionColor: UIColor) {
        isTitleLabelHighlighted = highlighted
        titleHTML = html
        titleTextStyle = textStyle
        titleColor = color
        titleSelectionColor = selectionColor
        updateTitle()
    }

    private var styles: HtmlUtils.Styles {
        let color = isTitleLabelHighlighted ? titleSelectionColor : titleColor
        return HtmlUtils.Styles(font: WMFFont.for(titleTextStyle, compatibleWith: traitCollection), boldFont: WMFFont.for(titleTextStyle == .georgiaTitle3 ? .boldGeorgiaTitle3 : .boldSubheadline, compatibleWith: traitCollection), italicsFont: WMFFont.for(titleTextStyle == .georgiaTitle3 ? .italicGeorgiaTitle3 : .italicSubheadline, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(titleTextStyle == .georgiaTitle3 ? .boldItalicGeorgiaTitle3 : .boldItalicSubheadline, compatibleWith: traitCollection), color: color, linkColor: titleSelectionColor, lineSpacing: 3)
    }

    func updateTitle() {
        titleLabel.attributedText = NSAttributedString.attributedStringFromHtml(titleHTML, styles: styles)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateTitle()
    }
    
    private var titleColor: UIColor = Theme.standard.colors.primaryText {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    
    private var titleSelectionColor: UIColor = Theme.standard.colors.link
    
    
    // MARK: - Init

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        indentationWidth = 10
    }
    
    // MARK: - UIView

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedSectionIndicator.alpha = 0.0
        selectionStyle = .none
    }
    
    // MARK: - Accessors
    
    func setSectionSelected(_ selected: Bool, animated: Bool) {
        if selected {
            setSelectionIndicatorVisible(titleIndentationLevel == 0)
        } else {
            setSelectionIndicatorVisible(false)
        }
    }
    
    // MARK: - UITableVIewCell

    class func reuseIdentifier() -> String {
        return wmf_nibName()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        indentationLevel = 1
        setSectionSelected(false, animated: false)
        isTitleLabelHighlighted = false
        accessibilityTraits = []
        accessibilityValue = nil
    }
    
    
    func setSelectionIndicatorVisible(_ visible: Bool) {
        if visible {
            selectedSectionIndicator.backgroundColor = titleSelectionColor
            selectedSectionIndicator.alpha = 1.0
        } else {
            selectedSectionIndicator.alpha = 0.0

        }
    }
    
}
