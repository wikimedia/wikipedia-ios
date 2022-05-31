import UIKit

class DisappearingCallbackNavigationController: WMFThemeableNavigationController {
    
    var willDisappearCallback: (() -> Void)?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        willDisappearCallback?()
    }
}
