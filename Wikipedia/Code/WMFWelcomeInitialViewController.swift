// A lightweight way to provide iPhone X friendly constraints when using a UIPageViewController
// is to simply embed it in a container view which uses such constraints. No need to modify the
// UIPageViewController subclass at all. WMFWelcomeInitialViewController embeds a UIPageViewController
// in such a container view.
class WMFWelcomeInitialViewController: UIViewController {
    @objc var completionBlock: (() -> Void)?
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? WMFWelcomePageViewController else {
            assertionFailure("Expected a WMFWelcomePageViewController")
            return
        }
        vc.completionBlock = completionBlock
    }
}
