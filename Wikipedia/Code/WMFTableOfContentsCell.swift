
import UIKit

// MARK: - Cell
public class WMFTableOfContentsCell: UITableViewCell {
    @IBOutlet var sectionSelectionBackground: UIView!
    @IBOutlet var sectionTitle: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet var sectionBorder: UIView!
    @IBOutlet var sectionBorderAlignLeadingToSuperview: NSLayoutConstraint!
    @IBOutlet var sectionBorderAlignToText: NSLayoutConstraint!
    
    // MARK: - Init

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        indentationWidth = 10
    }
    
    // MARK: - UIView

    public override func awakeFromNib() {
        super.awakeFromNib()
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

            switch (newItem.borderType) {
            case .Default:
                sectionBorder.hidden = false
                sectionBorderAlignToText.active = true
                sectionBorderAlignLeadingToSuperview.active = false
            case .FullWidth:
                sectionBorder.hidden = false
                sectionBorderAlignToText.active = false
                sectionBorderAlignLeadingToSuperview.active = true
            case .None:
                sectionBorder.hidden = true
            }

            indentationConstraint.constant =
                WMFTableOfContentsCell.indentationConstantForItem(item)

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
    static let indentationLevelSpacing: CGFloat = 10

    static func indentationConstantForItem(item: TableOfContentsItem?) -> CGFloat {
        return WMFTableOfContentsCell.minimumIndentationWidth
               + WMFTableOfContentsCell.indentationLevelSpacing * CGFloat(item?.indentationLevel ?? 0)
    }
}
