
import UIKit

class LoadingAnimationViewController: UIViewController {
    
    var cancelBlock: (() -> Void)?
    @IBOutlet private var satelliteImageView: UIImageView!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var backgroundImageView: UIImageView!
    @IBOutlet private var loadingPageLabel: UILabel!
    
    var theme: Theme?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let theme = theme {
            apply(theme: theme)
        }
        
        cancelButton.setTitle(CommonStrings.cancelActionTitle, for: .normal)
        loadingPageLabel.text = WMFLocalizedString("link-loading-title", value: "Loading page...", comment: "Title displayed in loading overlay after link is tapped.")
        view.accessibilityViewIsModal = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        satelliteImageView.startRotating()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: loadingPageLabel)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        satelliteImageView.stopRotating()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
    }
    

    @IBAction func tappedCancel(_ sender: UIButton) {
        cancelBlock?()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cancelButton.titleLabel?.font = UIFont.wmf_font(.semiboldTitle3, compatibleWithTraitCollection: traitCollection)
        loadingPageLabel.font = UIFont.wmf_font(.boldHeadline, compatibleWithTraitCollection: traitCollection)
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
        backgroundView.backgroundColor = theme.colors.paperBackground
        cancelButton.setTitleColor(theme.colors.link, for: .normal)
        backgroundImageView.tintColor = theme.colors.animationBackground
        loadingPageLabel.textColor = theme.colors.primaryText
    }
}
