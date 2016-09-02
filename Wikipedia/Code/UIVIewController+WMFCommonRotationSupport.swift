import UIKit

public extension UIViewController {
    public func wmf_orientationMaskPortraitiPhoneAnyiPad() -> UIInterfaceOrientationMask{
        if(UI_USER_INTERFACE_IDIOM() == .Pad){
            return .All;
        }else{
            return .Portrait;
        }
    }
}