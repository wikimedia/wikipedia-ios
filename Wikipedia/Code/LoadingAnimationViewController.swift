import WMFComponents

class LoadingAnimationViewController: UIViewController {
    
    var theme: Theme = Theme.standard
    
    var cancelBlock: (() -> Void)?
    @IBOutlet private var satelliteImageView: UIImageView!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apply(theme: theme)
        
        cancelButton.setTitle(CommonStrings.cancelActionTitle, for: .normal)
        statusLabel.text = WMFLocalizedString("data-migration-status", value: "Updating...", comment: "Message displayed during a long running data migration.")
        view.accessibilityViewIsModal = true
        
        updateFonts()
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        satelliteImageView.startRotating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        satelliteImageView.startRotating()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: statusLabel)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        satelliteImageView.stopRotating()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @IBAction func tappedCancel(_ sender: UIButton) {
        cancelBlock?()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }
    
    private func updateFonts() {
        cancelButton.titleLabel?.font = WMFFont.for(.semiboldTitle3, compatibleWith: traitCollection)
        statusLabel.font = WMFFont.for(.boldHeadline, compatibleWith: traitCollection)
    }
}

private extension UIView {
    
    var rotationKey: String {
        return "rotation"
    }
    
    func startRotating(duration: Double = 1) {
        let kAnimationKey = rotationKey
        
        if layer.animation(forKey: kAnimationKey) == nil {
            let animate = CABasicAnimation(keyPath: "transform.rotation")
            animate.duration = duration
            animate.repeatCount = Float.infinity
            animate.fromValue = 0.0
            animate.toValue = Float(.pi * 2.0)
            layer.add(animate, forKey: kAnimationKey)
        }
    }
    func stopRotating() {
        let kAnimationKey = rotationKey
        
        if self.layer.animation(forKey: kAnimationKey) != nil {
            self.layer.removeAnimation(forKey: kAnimationKey)
        }
    }
}

extension LoadingAnimationViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        backgroundView.backgroundColor = theme.colors.paperBackground
        cancelButton.setTitleColor(theme.colors.link, for: .normal)
        backgroundImageView.tintColor = theme.colors.animationBackground
        statusLabel.textColor = theme.colors.primaryText
    }
}
