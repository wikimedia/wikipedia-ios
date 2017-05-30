import UIKit

class NewsCollectionViewHeader: UICollectionReusableView {
    @IBOutlet weak var label: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        wmf_configureSubviewsForDynamicType()
    }
    
}
