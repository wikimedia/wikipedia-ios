
extension UIViewController {
    /**
     * Convenience method for creating an instance of the receiver from a storyboard.
     *
     * The view controller in the storyboard must have its identifier set to the same name as the receiver's class because this method uses String(self) as the sought indentifier. As such, this method is not useful if the sought view controller type occurs more than once in the storyboard.
     *
     *  @param storyboardName The name of the storyboard used to load the receiver's view.
     *
     *  @return A new instance of the receiver loaded from the storyboard.
     */
    @objc class func wmf_viewControllerFromStoryboardNamed(_ storyboardName:String) -> Self {
        return wmf_viewController(withIdentifier: String(describing: self), fromStoryboardNamed:storyboardName)
    }
}

