import UIKit

class TextSizeChangeExampleViewController: UIViewController {
    
    fileprivate var theme = Theme.standard
    
    @IBOutlet weak var textSizeChangeExampleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: self.theme)
        //localize
        textSizeChangeExampleLabel.text = "Drag the slider above to change the article text sizing. Utilize your system text size to resize other text areas in the app."
        
        //TODO: update notification name
        NotificationCenter.default.addObserver(self, selector: #selector(self.textSizeChanged(notification:)), name: NSNotification.Name(rawValue: FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    func textSizeChanged(notification: Notification) {
        if let multiplier = notification.userInfo?[FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey] as? NSNumber {
            textSizeChangeExampleLabel.font = textSizeChangeExampleLabel.font.withSize(15*CGFloat(multiplier)/100)
        }
    }
    
}

extension TextSizeChangeExampleViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.baseBackground
        textSizeChangeExampleLabel.textColor = theme.colors.primaryText
    }
    
}
