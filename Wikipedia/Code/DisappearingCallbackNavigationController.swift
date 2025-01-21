import UIKit
import WMFComponents

class DisappearingCallbackNavigationController: WMFComponentNavigationController {
    
    var willDisappearCallback: (() -> Void)?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        willDisappearCallback?()
    }
}
