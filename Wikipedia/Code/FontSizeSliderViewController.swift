import UIKit

@objc(WMFFontSizeSliderViewController)
class FontSizeSliderViewController: UIViewController {
    
    @IBOutlet weak var slider: StepSlider!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    fileprivate var theme = Theme.standard
    
    @objc static let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"
    @objc static let WMFArticleFontSizeUpdatedNotification = "WMFArticleFontSizeUpdatedNotification"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.didLoad()
        apply(theme: self.theme)
        slider.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        slider.willAppear()
    }
    
    @IBAction func sliderValueChanged(_ sender: StepSlider) {
        let _ = slider.setNewValue(slider.value)
    }

}

extension FontSizeSliderViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.midBackground
        slider.backgroundColor = theme.colors.midBackground
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        if self.parent is AppearanceSettingsViewController {
            view.backgroundColor = theme.colors.paperBackground
            slider.backgroundColor = theme.colors.paperBackground
        }
    }
}

extension FontSizeSliderViewController: AccessibleSlider {
    func increment() -> Int? {
        let newValue = slider.value + 1
        return slider.setNewValue(newValue) ? newValue : nil
    }
    
    func decrement() -> Int? {
        let newValue = slider.value - 1
        return slider.setNewValue(newValue) ? newValue : nil
    }
}
