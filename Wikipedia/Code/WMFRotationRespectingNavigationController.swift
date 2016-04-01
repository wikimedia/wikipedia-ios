
import UIKit

public class WMFRotationRespectingNavigationController: UINavigationController {
    
    public override func shouldAutorotate() -> Bool {
        if let vc = self.topViewController {
            return vc.shouldAutorotate()
        }else{
            return super.shouldAutorotate()
        }
    }
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let vc = self.topViewController {
            return vc.supportedInterfaceOrientations()
        }else{
            return super.supportedInterfaceOrientations()
        }
    }
    
    public override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        if let vc = self.topViewController {
            return vc.preferredInterfaceOrientationForPresentation()
        }else{
            return super.preferredInterfaceOrientationForPresentation()
        }
    }
}
