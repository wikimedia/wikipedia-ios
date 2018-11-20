import UIKit

@objc(WMFEditToolbarAccessoryView)
class EditToolbarAccessoryView: UIView {
    @IBOutlet weak var editToolbar: EditToolbar!

    override func awakeFromNib() {
        super.awakeFromNib()
        addTopShadow(with: Theme.standard)
    }

    private func addTopShadow(with theme: Theme) {
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 10
        layer.shadowColor = theme.colors.shadow.cgColor
        layer.shadowOpacity = 1.0
    }
}
