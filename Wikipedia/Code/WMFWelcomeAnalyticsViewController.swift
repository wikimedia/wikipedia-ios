
class WMFWelcomeAnalyticsViewController: WMFWelcomeFadeInAndUpOnceViewController {
    
    @IBOutlet var animationView:WelcomeAnalyticsAnimationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animationView.backgroundColor = UIColor.clearColor()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.destinationViewController.isKindOfClass(WMFWelcomePanelViewController)){
            let panelVC = segue.destinationViewController as! WMFWelcomePanelViewController
            panelVC.useUsageReportsConfiguration()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let shouldAnimate = !hasAlreadyFaded
        super.viewDidAppear(animated)
        if(shouldAnimate){
            animationView.beginAnimations()
        }
    }
    
    @IBAction func showPrivacyPolicy(){
        wmf_openExternalUrl(NSURL.wmf_optionalURLWithString(URL_PRIVACY_POLICY))
    }
}
