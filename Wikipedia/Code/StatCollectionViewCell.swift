import UIKit

class StatCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageLabel: UILabel!

    @IBOutlet private weak var rightSeparator: UIView!

    enum Separator {
        case top, right
    }

    func configure(with title: String, image: UIImage, imageText: String, isRightSeparatorHidden: Bool) {
        titleLabel.text = title
        imageView.image = image
        imageLabel.text = imageText
        rightSeparator.isHidden = isRightSeparatorHidden
    }
}

extension StatCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        rightSeparator.backgroundColor = theme.colors.border
    }
}
