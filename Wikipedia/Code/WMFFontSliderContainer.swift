import UIKit

@objc public protocol WMFFontSliderViewControllerDelegate{
    
    func sliderValueChangedInController(controller: WMFFontSliderViewController, value: Int)
}

public class WMFFontSliderViewController: UIViewController {

    @IBOutlet private var slider: SWStepSlider!
    private var maximumValue: Int?
    private var currentValue: Int?
    
    var visible = false
    
    public weak var delegate: WMFFontSliderViewControllerDelegate?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if let max = self.maximumValue {
            if let current = self.currentValue {
                self.setValues(0, maximum: max, current: current)
                self.maximumValue = nil
                self.currentValue = nil
            }
        }
    }
    
    public func setValuesWithSteps(steps: Int, current: Int) {
        if self.isViewLoaded() {
            self.setValues(0, maximum: steps-1, current: current)
        }else{
            maximumValue = steps-1
            currentValue = current
        }
    }
    
    func setValues(minimum: Int, maximum: Int, current: Int){
        self.slider.minimumValue = minimum
        self.slider.maximumValue = maximum
        self.slider.value = current
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        visible = true
    }
    
    @IBAction func fontSliderValueChanged(slider: SWStepSlider) {
        if let delegate = self.delegate where visible {
            delegate.sliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    
}

