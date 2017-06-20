import UIKit

class OnThisDayCollectionViewHeader: UICollectionReusableView {
    @IBOutlet weak var label: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        wmf_configureSubviewsForDynamicType()
    }
    
}
