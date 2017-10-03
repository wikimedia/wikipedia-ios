
extension UIViewController {
    @objc class func wmf_viewControllerFromWelcomeStoryboard() -> Self {
        return wmf_viewControllerFromStoryboardNamed("WMFWelcome")
    }
}
