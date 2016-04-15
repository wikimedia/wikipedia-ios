
import UIKit

public class WMFRotationRespectingTabBarController: UITabBarController {

    public override func shouldAutorotate() -> Bool {
        if let vc = self.presentedViewController {
            return vc.shouldAutorotate()
        } else if let vc = self.selectedViewController {
            return vc.shouldAutorotate()
        }else{
            return super.shouldAutorotate()
        }
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let vc = self.presentedViewController {
            return vc.supportedInterfaceOrientations()
        } else if let vc = self.selectedViewController {
            return vc.supportedInterfaceOrientations()
        }else{
            return super.supportedInterfaceOrientations()
        }
    }
    
    public override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        if let vc = self.presentedViewController {
            return vc.preferredInterfaceOrientationForPresentation()
        } else if let vc = self.selectedViewController {
            return vc.preferredInterfaceOrientationForPresentation()
        }else{
            return super.preferredInterfaceOrientationForPresentation()
        }
    }
}
