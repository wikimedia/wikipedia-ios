import UIKit

public extension UIViewController {
    @objc func wmf_orientationMaskPortraitiPhoneAnyiPad() -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }
}
