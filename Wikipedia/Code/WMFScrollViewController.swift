
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
}
