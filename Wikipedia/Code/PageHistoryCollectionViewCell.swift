import UIKit

class PageHistoryCollectionViewCell: CollectionViewCell {
    override func setup() {
        super.setup()
        layer.cornerRadius = 6
        layer.masksToBounds = true
        layer.borderColor = UIColor.yellow.cgColor
        layer.borderWidth = 1
    }
}

extension PageHistoryCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        layer.borderColor = theme.colors.border.cgColor
    }
}
