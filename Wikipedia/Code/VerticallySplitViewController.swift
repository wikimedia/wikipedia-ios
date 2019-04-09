import UIKit

class VerticallySplitViewController: UIViewController {
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var bottomView: UIView!

    private let topViewController: UIViewController
    private let bottomViewController: UIViewController

    init(topViewController: UIViewController, bottomViewController: UIViewController) {
        self.topViewController = topViewController
        self.bottomViewController = bottomViewController
        super.init(nibName: "VerticallySplitViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
