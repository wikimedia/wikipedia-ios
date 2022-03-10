import UIKit
 
@objc public protocol SettingsPresentationDelegate: NSObjectProtocol {
    func userDidTapSettings(from viewController: UIViewController?)
}
