import Foundation

extension UIViewController {
    @objc class func wmf_viewControllerFromTalkPageStoryboard() -> Self {
        return wmf_viewControllerFromStoryboardNamed("TalkPage")
    }
}
