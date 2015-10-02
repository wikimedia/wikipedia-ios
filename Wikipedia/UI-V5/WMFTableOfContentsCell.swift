
import UIKit

// MARK: - Cell
public class WMFTableOfContentsCell: UITableViewCell {

    @IBOutlet var sectionTitle: UILabel!
    @IBOutlet var selectedSectionIndicator: UIView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    
    // MARK: - Init
    public required init?(coder aDecoder: NSCoder) {
        section = nil
        super.init(coder: aDecoder);
        self.indentationWidth = 10
    }
    
    // MARK: - UIView
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.selectedSectionIndicator.alpha = 0.0
        let bg = UIView.init(frame: self.bounds);
        bg.backgroundColor = UIColor.wmf_tableOfContentsSelectionBackgroundColor()
        self.selectedBackgroundView = bg
    }
    
    // MARK: - Accessors
    public var section: MWKSection?{
        didSet(section) {
            self.sectionTitle.text = WMFTableOfContentsCell.titleText(self.section)
            self.sectionTitle.font = WMFTableOfContentsCell.titleFont(self.section)
            self.sectionTitle.textColor = WMFTableOfContentsCell.textColor(self.section)
            self.indentationConstraint.constant = WMFTableOfContentsCell.indentationWidth(self.section)
            self.setNeedsUpdateConstraints()
        }
    }
    
    // MARK: - UITableVIewCell
    public class func reuseIdentifier() -> String{
        return self.wmf_nibName()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.section = nil
        self.setSelected(false, animated: false)
    }
    
    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(selected){
            //HACK: I don't know why I have to set the color here, but I do. Something is setting it to clear background color
            self.selectedSectionIndicator.backgroundColor = UIColor.wmf_tableOfContentsSelectionIndicatorColor()
            self.selectedSectionIndicator.alpha = 1.0
        }else{
            self.selectedSectionIndicator.alpha = 0.0
        }
    }
    
    // MARK: - Title
    class func titleText(section: MWKSection?) -> String?{
        guard let section = section else{
            return nil
        }
        
        if(section.isLeadSection()){
            if let text = section.article?.title.text{
                return text
            }else{
                return nil
            }
        }else{
            return section.line
        }
    }
    
    // MARK: - Font
    class func titleFont(section: MWKSection?) -> UIFont{
        if let level = section?.toclevel?.integerValue {
            if(level == 0){
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
            if(level == 0){
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

