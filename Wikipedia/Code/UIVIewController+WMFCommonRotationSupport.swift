import UIKit

public extension UIViewController {
    @objc func wmf_orientationMaskPortraitiPhoneAnyiPad() -> UIInterfaceOrientationMask{
        if(UI_USER_INTERFACE_IDIOM() == .pad){
            return .all;
        }else{
            return .portrait;
        }
    }
}
