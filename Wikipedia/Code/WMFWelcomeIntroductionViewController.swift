
class WMFWelcomeIntroductionViewController: WMFWelcomeFadeInAndUpOnceViewController {
    
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var subTitleLabel:UILabel!
    @IBOutlet private var tellMeMoreButton:UIButton!
    @IBOutlet private var nextButton:UIButton!
    @IBOutlet private var animationView:WelcomeIntroAnimationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-explore-title").uppercaseStringWithLocale(NSLocale.currentLocale())
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-explore-sub-title")
        tellMeMoreButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more"), forState: .Normal)
        nextButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-explore-continue-button").uppercaseStringWithLocale(NSLocale.currentLocale()), forState: .Normal)
        animationView.backgroundColor = UIColor.clearColor()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func viewDidAppear(animated: Bool) {
        let shouldAnimate = !hasAlreadyFaded
        super.viewDidAppear(animated)
        if(shouldAnimate){
            animationView.beginAnimations()
        }
    }
    
    @IBAction private func showHowThisWorksAlert(withSender sender: AnyObject) {
        let alert = UIAlertController(
            title:localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more-about-explore"),
            message:"\(localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more-related"))\n\n\(localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more-privacy"))",
            preferredStyle:.Alert)
        alert.addAction(UIAlertAction(title:localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more-done-button"), style:.Cancel, handler:nil))
        presentViewController(alert, animated:true, completion:nil)
    }
}
