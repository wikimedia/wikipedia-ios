
import UIKit

class LoadingAnimationViewController: UIViewController {
    
    var cancelBlock: (() -> Void)?
    @IBOutlet private var satelliteImageView: UIImageView!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var cancelButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cancelButton.setTitle(CommonStrings.cancelActionTitle, for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        satelliteImageView.startRotating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        satelliteImageView.stopRotating()
    }
    

    @IBAction func tappedCancel(_ sender: UIButton) {
        cancelBlock?()
    }
}

private extension UIView {
    func startRotating(duration: Double = 1) {
        let kAnimationKey = "rotation"
        
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
        let kAnimationKey = "rotation"
        
        if self.layer.animation(forKey: kAnimationKey) != nil {
            self.layer.removeAnimation(forKey: kAnimationKey)
        }
    }
}

extension LoadingAnimationViewController: Themeable {
    func apply(theme: Theme) {
        backgroundView.backgroundColor = theme.colors.paperBackground
        cancelButton.setTitleColor(theme.colors.link, for: .normal)
    }
}
