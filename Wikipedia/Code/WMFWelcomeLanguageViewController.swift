
class WMFWelcomeLanguageViewController: WMFWelcomeFadeInAndUpOnceViewController {
    
    @IBOutlet var animationView:WelcomeLanguagesAnimationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animationView.backgroundColor = UIColor.clearColor()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.destinationViewController.isKindOfClass(WMFWelcomePanelViewController)){
            let panelVC = segue.destinationViewController as! WMFWelcomePanelViewController
            panelVC.useLanguagesConfiguration()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let shouldAnimate = !hasAlreadyFaded
        super.viewDidAppear(animated)
        if(shouldAnimate){
            animationView.beginAnimations()
        }
    }
}
