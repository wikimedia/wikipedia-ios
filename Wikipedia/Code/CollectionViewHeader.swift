import UIKit

class CollectionViewHeader: WMFExploreCollectionReusableView {
    @IBOutlet weak var label: UILabel!
    
    var text: String? {
        didSet {
            label.text = text?.uppercased()
        }
    }
}
