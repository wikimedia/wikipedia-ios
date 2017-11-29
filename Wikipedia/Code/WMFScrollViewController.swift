
import UIKit

class WMFScrollViewController: UIViewController, WMFScrollable {
    @IBOutlet internal var scrollView: UIScrollView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wmf_beginAdjustingScrollViewInsetsForKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        wmf_endAdjustingScrollViewInsetsForKeyboard()
        super.viewWillDisappear(animated)
    }
    
    fileprivate var coverView: UIView?
    func setViewControllerUserInteraction(enabled: Bool) {
        if enabled {
            coverView?.removeFromSuperview()
        } else if coverView == nil {
            let newCoverView = UIView()
            newCoverView.backgroundColor = view.backgroundColor
            newCoverView.alpha = 0.8
            view.wmf_addSubviewWithConstraintsToEdges(newCoverView)
            coverView = newCoverView
        }
        view.isUserInteractionEnabled = enabled
    }
}
