
import UIKit

// MARK: - Cell
public class WMFTableOfContentsCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    
    public var titleIndentationLevel: Int = 0 {
        didSet {
            titleLabelTopConstraint.constant = titleIndentationLevel == 0 ? 19 : 11;
            indentationConstraint.constant =  indentationWidth * CGFloat(1 + titleIndentationLevel)
        }
    }
    
    public var titleColor: UIColor = UIColor.blackColor() {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    
    // MARK: - Init

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        indentationWidth = 10
    }
    
    // MARK: - UIView

    public override func awakeFromNib() {
        super.awakeFromNib()
        selectedSectionIndicator.alpha = 0.0
        selectionStyle = .None
    }
    
    // MARK: - Accessors
    
    public func setSectionSelected(selected: Bool, animated: Bool) {
        if (selected) {
            setSelectionIndicatorVisible(titleIndentationLevel == 0)
        } else {
            setSelectionIndicatorVisible(false)
        }
    }
    
    // MARK: - UITableVIewCell

    public class func reuseIdentifier() -> String{
        return wmf_nibName()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        indentationLevel = 0
        setSectionSelected(false, animated: false)
        setSelected(false, animated: false)
    }
    
    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(selected){
            setTitleLabelHighlighted(true)
        } else {
            setTitleLabelHighlighted(false)
        }
    }
    
    public func setTitleLabelHighlighted(highlighted: Bool) {
        if highlighted {
            titleLabel.textColor = UIColor.wmf_tableOfContentsSelectionIndicatorColor()
        } else {
            titleLabel.textColor = titleColor
        }
    }
    
    public func setSelectionIndicatorVisible(visible: Bool) {
        if (visible) {
            selectedSectionIndicator.backgroundColor = UIColor.wmf_tableOfContentsSelectionIndicatorColor()
            selectedSectionIndicator.alpha = 1.0
        } else {
            selectedSectionIndicator.alpha = 0.0

        }
    }
    
}
