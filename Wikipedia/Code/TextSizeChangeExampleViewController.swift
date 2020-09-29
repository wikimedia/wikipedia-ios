import UIKit

class TextSizeChangeExampleViewController: UIViewController {
    
    fileprivate var theme = Theme.standard
    
    @IBOutlet weak var textSizeChangeExampleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: self.theme)
        textSizeChangeExampleLabel.text = WMFLocalizedString("appearance-settings-text-sizing-example-text", value: "Drag the slider to change the article text sizing. Utilize your system text size to resize other text areas in the app.", comment: "Example text of the Adjust article text sizing section in Appearance settings")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.textSizeChanged(notification:)), name: NSNotification.Name(rawValue: FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    @objc func textSizeChanged(notification: Notification) {
        if let multiplier = notification.userInfo?[FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey] as? NSNumber {
            textSizeChangeExampleLabel.font = textSizeChangeExampleLabel.font.withSize(15*CGFloat(truncating: multiplier)/100)
        }
    }
    
}

extension TextSizeChangeExampleViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        textSizeChangeExampleLabel.textColor = theme.colors.primaryText
    }
    
}
