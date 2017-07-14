import UIKit

@objc public protocol WMFFontSliderViewControllerDelegate {
    
    func sliderValueChangedInController(_ controller: WMFReadingThemesControlsViewController, value: Int)
}

open class WMFReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    var visible = false
    
    open weak var fontSliderDelegate: WMFFontSliderViewControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let max = self.maximumValue {
            if let current = self.currentValue {
                self.setValues(0, maximum: max, current: current)
                self.maximumValue = nil
                self.currentValue = nil
            }
        }
        brightnessSlider.value = Float(UIScreen.main.brightness)
        
    }
    
    open func setValuesWithSteps(_ steps: Int, current: Int) {
        if self.isViewLoaded {
            self.setValues(0, maximum: steps-1, current: current)
        }else{
            maximumValue = steps-1
            currentValue = current
        }
    }
    
    func setValues(_ minimum: Int, maximum: Int, current: Int){
        self.slider.minimumValue = minimum
        self.slider.maximumValue = maximum
        self.slider.value = current
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visible = true
    }
    
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    @IBAction func fontSliderValueChanged(_ slider: SWStepSlider) {
        if let delegate = self.fontSliderDelegate, visible {
            delegate.sliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    @IBAction func changeThemeButtonPressed(_ sender: UIButton) {
        var theme = [String: Theme]()
        
        switch sender.tag {
        case 0:
            theme["theme"] = Theme.standard
        case 1:
            theme["theme"] = Theme.light
        case 2:
            theme["theme"] = Theme.dark
        default:
            break
        }
        
        NotificationCenter.default.post(name: Notification.Name(WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
}
