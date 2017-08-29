import UIKit

// MARK: - Cell
open class WMFTableOfContentsCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    
    open var titleIndentationLevel: Int = 0 {
        didSet {
            titleLabelTopConstraint.constant = titleIndentationLevel == 0 ? 19 : 11;
            indentationConstraint.constant =  indentationWidth * CGFloat(1 + titleIndentationLevel)
        }
    }
    
    open var titleColor: UIColor = Theme.standard.colors.primaryText {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    
    open var selectionColor: UIColor = Theme.standard.colors.link
    
    
    // MARK: - Init

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        indentationWidth = 10
    }
    
    // MARK: - UIView

    open override func awakeFromNib() {
        super.awakeFromNib()
        selectedSectionIndicator.alpha = 0.0
        selectionStyle = .none
    }
    
    // MARK: - Accessors
    
    open func setSectionSelected(_ selected: Bool, animated: Bool) {
        if (selected) {
            setSelectionIndicatorVisible(titleIndentationLevel == 0)
        } else {
            setSelectionIndicatorVisible(false)
        }
    }
    
    // MARK: - UITableVIewCell

    open class func reuseIdentifier() -> String{
        return wmf_nibName()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        indentationLevel = 0
        setSectionSelected(false, animated: false)
        setSelected(false, animated: false)
    }
    
    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(selected){
            setTitleLabelHighlighted(true)
        } else {
            setTitleLabelHighlighted(false)
        }
    }
    
    open func setTitleLabelHighlighted(_ highlighted: Bool) {
        if highlighted {
            titleLabel.textColor = selectionColor
        } else {
            titleLabel.textColor = titleColor
        }
    }
    
    open func setSelectionIndicatorVisible(_ visible: Bool) {
        if (visible) {
            selectedSectionIndicator.backgroundColor = selectionColor
            selectedSectionIndicator.alpha = 1.0
        } else {
            selectedSectionIndicator.alpha = 0.0

        }
    }
    
}
