import UIKit

@objc public protocol WMFFontSliderViewControllerDelegate {
    
    func sliderValueChangedInController(_ controller: WMFReadingThemesControlsViewController, value: Int)
}

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func darkThemeButtonPressedInController(_ controller: WMFReadingThemesControlsViewController)
}

open class WMFReadingThemesControlsViewController: UIViewController {
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var defaultThemeButton: UIButton!
    @IBOutlet weak var sepiaThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    
    var visible = false
    
    open weak var fontSliderDelegate: WMFFontSliderViewControllerDelegate?
    open weak var readingThemesControlsDelegate: WMFReadingThemesControlsViewControllerDelegate?
    
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
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        print("darkThemeButtonPressed in WMFReadingThemesControlsViewController")
        if let delegate = self.readingThemesControlsDelegate, visible {
            print("win")
            delegate.darkThemeButtonPressedInController(self)
        }
    }
    
    
}

