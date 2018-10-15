// A lightweight way to provide iPhone X friendly constraints when using a UIPageViewController
// is to simply embed it in a container view which uses such constraints. No need to modify the
// UIPageViewController subclass at all. DescriptionWelcomeInitialViewController embeds a UIPageViewController
// in such a container view.
class DescriptionWelcomeInitialViewController: UIViewController, Themeable {
    private var theme = Theme.standard
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.midBackground
    }

    @objc var completionBlock: (() -> Void)?
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? DescriptionWelcomePageViewController else {
            assertionFailure("Expected a DescriptionWelcomePageViewController")
            return
        }
        vc.apply(theme: theme)
        vc.completionBlock = completionBlock
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
}
