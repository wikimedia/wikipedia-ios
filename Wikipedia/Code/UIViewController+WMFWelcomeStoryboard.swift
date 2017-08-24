
extension UIViewController {
    @objc class func wmf_viewControllerFromWelcomeStoryboard() -> Self {
        return self.wmf_viewControllerFromStoryboardNamed("WMFWelcome")
    }
}
