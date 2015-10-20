
import UIKit

// MARK: - Cell
public class WMFTableOfContentsCell: UITableViewCell {

    @IBOutlet var sectionSelectionBackground: UIView!
    @IBOutlet var sectionTitle: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet var leadSectionBorder: UIView!
    @IBOutlet var sectionBorder: UIView!
    
    // MARK: - Init
    public required init?(coder aDecoder: NSCoder) {
        section = nil
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
    public var section: MWKSection?{
        didSet(section) {
            sectionTitle.text = WMFTableOfContentsCell.titleText(section)
            sectionTitle.font = WMFTableOfContentsCell.titleFont(section)
            sectionTitle.textColor = WMFTableOfContentsCell.textColor(section)
            leadSectionBorder.hidden = !WMFTableOfContentsCell.leadSectionBorderEnabled(section)
            sectionBorder.hidden = !WMFTableOfContentsCell.topBorderEnabled(section)
            indentationConstraint.constant = WMFTableOfContentsCell.indentationWidth(section)
            setNeedsUpdateConstraints()
        }
    }
    
    public func setSectionSelected(selected: Bool, animated: Bool) {
        UIView.animateWithDuration(animated ? 0.3 : 0.0) {
            if(selected){
                self.sectionSelectionBackground.alpha = 1.0
            }else{
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
        section = nil
        leadSectionBorder.hidden = true
        sectionBorder.hidden = true
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

    // MARK: - Border
    class func leadSectionBorderEnabled(section: MWKSection?) -> Bool{
        guard let section = section else{
            return false
        }
        if(section.sectionId == 1){
            return true
        }else{
            return false
        }
    }

    class func topBorderEnabled(section: MWKSection?) -> Bool{
        if let level = section?.toclevel?.integerValue {
            if(level < 2){
                return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
    // MARK: - Title
    class func titleText(section: MWKSection?) -> String?{
        guard let section = section else{
            return nil
        }
        if(section.isLeadSection()){
            return section.title.text
        }else if let line = section.line {
            return line.wmf_stringByRemovingHTML()
        }else{
            return nil
        }
    }
    
    // MARK: - Font
    class func titleFont(section: MWKSection?) -> UIFont{
        if let level = section?.toclevel?.integerValue {
            if(level < 2){
                return UIFont.wmf_tableOfContentsSectionFont()
            }else{
                return UIFont.wmf_tableOfContentsSubsectionFont()
            }
        }else{
            return UIFont.wmf_tableOfContentsSectionFont()
        }
    }
    
    class func textColor(section: MWKSection?) -> UIColor{
        if let level = section?.toclevel?.integerValue {
            if(level < 2){
                return UIColor.wmf_tableOfContentsSectionTextColor()
            }else{
                return UIColor.wmf_tableOfContentsSubsectionTextColor()
            }
        }else{
            return UIColor.wmf_tableOfContentsSectionTextColor()
        }
    }
    
    // MARK: - Indentation
    static let minimumIndentationWidth: CGFloat = 10
    static let indentationLevelSpacing: CGFloat = 10
    
    class func indentationWidth(section: MWKSection?) -> CGFloat{
        
        func indentationLevel(section: MWKSection) -> Int{
            if var level = section.toclevel?.integerValue {
                if level > 0 {
                    level = level - 1
                }
                return level;
            }else{
                return 0
            }
        }

        var indentationWidth = WMFTableOfContentsCell.minimumIndentationWidth
        if let section = section {
            indentationWidth += CGFloat(indentationLevel(section)) * CGFloat(WMFTableOfContentsCell.indentationLevelSpacing)
        }
        return indentationWidth
    }
}
