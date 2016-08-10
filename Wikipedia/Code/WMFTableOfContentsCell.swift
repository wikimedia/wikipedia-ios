
import UIKit

// MARK: - Cell
public class WMFTableOfContentsCell: UITableViewCell {
    @IBOutlet var sectionSelectionBackground: UIView!
    @IBOutlet var sectionTitle: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sectionLine: UIView!
    // MARK: - Init

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        indentationWidth = 10
    }
    
    // MARK: - UIView

    public override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = UIColor.wmf_tableOfContentsBackgroundColor()
        selectedSectionIndicator.alpha = 0.0
        sectionSelectionBackground.backgroundColor = UIColor.wmf_tableOfContentsSelectionBackgroundColor()
        sectionSelectionBackground.alpha = 0.0
        selectionStyle = .None
    }
    
    // MARK: - Accessors

    public func setItem(item: TableOfContentsItem?) {
        if let newItem: TableOfContentsItem = item {
            sectionTitle.text = newItem.titleText
            sectionTitle.font = newItem.itemType.titleFont
            sectionTitle.textColor = newItem.itemType.titleColor

            indentationConstraint.constant =
                WMFTableOfContentsCell.indentationConstantForItem(item)
            
            if let level = item?.indentationLevel where level > 1 {
                sectionLine.hidden = false
            } else {
                sectionLine.hidden = true
            }

            layoutIfNeeded()
        } else {
            sectionTitle.text = ""
        }
    }
    
    public func setSectionSelected(selected: Bool, animated: Bool) {
        if(selected && self.sectionSelectionBackground.alpha > 0){
            return;
        }
        if(!selected && self.sectionSelectionBackground.alpha == 0){
            return;
        }
        UIView.animateWithDuration(animated ? 0.3 : 0.0) {
            if (selected) {
                self.sectionSelectionBackground.alpha = 1.0
            } else {
                self.sectionSelectionBackground.alpha = 0.0
            }
        }
    }
    
    // MARK: - UITableVIewCell

    public class func reuseIdentifier() -> String{
        return wmf_nibName()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        setItem(nil)
        setSelected(false, animated: false)
        sectionSelectionBackground.alpha = 0.0
    }
    
    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(selected){
            //HACK: I don't know why I have to set the color here, but I do. Something is setting it to clear background color
            selectedSectionIndicator.backgroundColor = UIColor.wmf_tableOfContentsSelectionIndicatorColor()
            selectedSectionIndicator.alpha = 1.0
        }else{
            selectedSectionIndicator.alpha = 0.0
        }
    }
    
    // MARK: - Indentation

    static let minimumIndentationWidth: CGFloat = 10
    static let firstIndendationWidth: CGFloat = 9
    static let indentationLevelSpacing: CGFloat = 18

    static func indentationConstantForItem(item: TableOfContentsItem?) -> CGFloat {
        let level = item?.indentationLevel ?? 0
        var indent = WMFTableOfContentsCell.minimumIndentationWidth;
        if level > 0 {
            indent += WMFTableOfContentsCell.firstIndendationWidth
        }
        if level > 1 {
           indent += WMFTableOfContentsCell.indentationLevelSpacing * CGFloat(level - 1)
        }
        return indent
    }
}
