
import UIKit

open class WMFRotationRespectingTabBarController: UITabBarController {

    open override func shouldAutorotate() -> Bool {
        if let vc = self.presentedViewController , !vc.isKind(of: UIAlertController.self) {
            return vc.shouldAutorotate
        } else if let vc = self.selectedViewController {
            return vc.shouldAutorotate
        }else{
            return super.shouldAutorotate
        }
    }
    
    open override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let vc = self.presentedViewController , !vc.isKind(of: UIAlertController.self) {
            return vc.supportedInterfaceOrientations
        } else if let vc = self.selectedViewController {
            return vc.supportedInterfaceOrientations
        }else{
            return super.supportedInterfaceOrientations
        }
    }
    
    open override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        if let vc = self.presentedViewController , !vc.isKind(of: UIAlertController.self) {
            return vc.preferredInterfaceOrientationForPresentation
        } else if let vc = self.selectedViewController {
            return vc.preferredInterfaceOrientationForPresentation
        }else{
            return super.preferredInterfaceOrientationForPresentation
        }
    }
}
