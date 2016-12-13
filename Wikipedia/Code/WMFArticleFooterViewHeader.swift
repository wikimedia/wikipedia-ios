import UIKit

open class WMFArticleFooterViewHeader: UIView {
    @IBOutlet open var headerLabel: UILabel!
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        headerLabel.accessibilityTraits = UIAccessibilityTraitHeader
    }
    
}
