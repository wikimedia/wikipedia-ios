import UIKit
 
@objc public protocol SettingsPresentationDelegate: NSObjectProtocol {
    func userDidTapProfile(from viewController: UIViewController?)
}
