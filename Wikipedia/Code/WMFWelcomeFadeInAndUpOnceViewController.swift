
@objc class WMFWelcomeFadeInAndUpOnceViewController: UIViewController {

    var hasAlreadyFaded = false
    weak var delegate:WMFWelcomeNavigationDelegate? = nil

    @IBOutlet private var containerView:UIView!
    @IBOutlet private var fadeInAndUpDelay:NSNumber! = 0
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (!hasAlreadyFaded) {
            containerView.wmf_zeroLayerOpacity()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!hasAlreadyFaded) {
            containerView.wmf_fadeInAndUpAfterDelay(CGFloat(fadeInAndUpDelay))
        }
        hasAlreadyFaded = true
    }
    
    @IBAction func next(withSender sender: AnyObject) {
        delegate?.showNextWelcomePage(self)
    }
}
