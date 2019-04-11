import UIKit

class UploadMediaViewController: UIViewController, Themeable {
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Upload"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: Theme) {

    }
}
