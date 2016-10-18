
class WMFWelcomeFadeInAndUpOnceViewController: UIViewController {

    var hasAlreadyFaded = false
    
    @IBOutlet private var fadeInAndUpDelay:NSNumber! = 0
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (!hasAlreadyFaded) {
            view.wmf_zeroLayerOpacity()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!hasAlreadyFaded) {
            view.wmf_fadeInAndUpAfterDelay(CGFloat(fadeInAndUpDelay))
        }
        hasAlreadyFaded = true
    }    
}
