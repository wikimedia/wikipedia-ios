// A lightweight way to provide iPhone X friendly constraints when using a UIPageViewController
// is to simply embed it in a container view which uses such constraints. No need to modify the
// UIPageViewController subclass at all. WMFWelcomeInitialViewController embeds a UIPageViewController
// in such a container view.
class WMFWelcomeInitialViewController: ThemeableViewController {
    @objc var completionBlock: (() -> Void)?
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? WMFWelcomePageViewController else {
            assertionFailure("Expected a WMFWelcomePageViewController")
            return
        }
        vc.apply(theme: theme)
        vc.completionBlock = completionBlock
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        for child in children {
            guard let themeable = child as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .portrait
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
}
