import UIKit

public class WMFArticleFooterViewHeader: UIView {
    @IBOutlet public var headerLabel: UILabel!
    
    public override func awakeFromNib() {
        headerLabel.accessibilityTraits = UIAccessibilityTraitHeader
    }
    
}
