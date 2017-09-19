import UIKit

class CollectionViewHeader: WMFExploreCollectionReusableView {
    @IBOutlet weak var label: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        wmf_configureSubviewsForDynamicType()
    }
    
    var text: String? {
        didSet {
            label.text = text?.uppercased()
        }
    }
}

extension CollectionViewHeader: Themeable {
    func apply(theme: Theme) {
        label.textColor = theme.colors.secondaryText
    }
}
