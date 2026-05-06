import UIKit

public extension UIViewController {
    func configureHidesBottomBarWhenPushed() {
        if #available(iOS 26, *) {
            hidesBottomBarWhenPushed = !(UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular)
        } else {
            hidesBottomBarWhenPushed = true
        }
    }
}
