import UIKit
import WMF

class ImageDimmingExampleViewController: UIViewController {
    
    @IBOutlet weak var exampleImage: UIImageView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    public static var bottomSpacing: CGFloat = 15
    
    fileprivate var theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomConstraint.constant = ImageDimmingExampleViewController.bottomSpacing
        apply(theme: self.theme)
    }
    
}

extension ImageDimmingExampleViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        if #available(iOS 11.0, *) {
            exampleImage.accessibilityIgnoresInvertColors = true
        }
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        exampleImage.alpha = theme.imageOpacity
    }
}
