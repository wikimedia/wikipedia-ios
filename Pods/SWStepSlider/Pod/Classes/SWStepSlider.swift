//
//  SWStepSlider.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 2/4/16.
//
//

import UIKit

open class SWStepSliderAccessibilityElement: UIAccessibilityElement {
    var minimumValue: Int = 0
    var maximumValue: Int = 4
    var value: Int = 2
    
    weak var slider: SWStepSlider?
    
    public init(accessibilityContainer container: AnyObject, slider: SWStepSlider) {
        self.slider = slider
        super.init(accessibilityContainer: container)
    }

    override open func accessibilityActivate() -> Bool {
        return true
    }
    
    override open func accessibilityIncrement() {
        let new = value + 1
        self.slider?.setValueAndUpdateView(new)
    }
    
    override open func accessibilityDecrement() {
        let new = value - 1
        self.slider?.setValueAndUpdateView(new)
    }
}



@IBDesignable
open class SWStepSlider: UIControl {
    @IBInspectable open var minimumValue: Int = 0 {
        didSet {
            if self.minimumValue != oldValue {
                if let e = self.thumbAccessabilityElement {
                    e.minimumValue = self.minimumValue
                    self.accessibilityElements = [e]
                }
            }
        }
    }
    @IBInspectable open var maximumValue: Int = 4 {
        didSet {
            if self.maximumValue != oldValue {
                if let e = self.thumbAccessabilityElement {
                    e.minimumValue = self.maximumValue
                    self.accessibilityElements = [e]
                }
            }
        }
    }
    @IBInspectable open var value: Int = 2 {
        didSet {
            if self.value != oldValue {
                if let e = self.thumbAccessabilityElement {
                    e.accessibilityValue = String(self.value)
                    e.value = self.value
                    self.accessibilityElements = [e]
                }
                if self.continuous {
                    self.sendActions(for: .valueChanged)
                }
            }
        }
    }
    
    @IBInspectable open var continuous: Bool = true // if set, value change events are generated any time the value changes due to dragging. default = YES
    
    let trackLayer = CALayer()
    open var trackHeight: CGFloat = 2
    open var trackColor = UIColor(red: 152.0/255.0, green: 152.0/255.0, blue: 152.0/255.0, alpha: 1)
    
    open var tickHeight: CGFloat = 8
    open var tickWidth: CGFloat = 2
    open var tickColor = UIColor(red: 152.0/255.0, green: 152.0/255.0, blue: 152.0/255.0, alpha: 1)
    
    let thumbLayer = CAShapeLayer()
    var thumbFillColor = UIColor.white
    var thumbStrokeColor = UIColor(red: 222.0/255.0, green: 222.0/255.0, blue: 222.0/255.0, alpha: 1)
    var thumbDimension: CGFloat = 28

    fileprivate var thumbAccessabilityElement: SWStepSliderAccessibilityElement?

    var stepWidth: CGFloat {
        return self.trackWidth / CGFloat(self.maximumValue)
    }
    
    var trackWidth: CGFloat {
        return self.bounds.size.width - self.thumbDimension
    }
    
    var trackOffset: CGFloat {
        return (self.bounds.size.width - self.trackWidth) / 2
    }
    
    var numberOfSteps: Int {
        return self.maximumValue - self.minimumValue + 1
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.trackLayer.backgroundColor = self.trackColor.cgColor
        self.layer.addSublayer(trackLayer)
        
        self.thumbLayer.backgroundColor = UIColor.clear.cgColor
        self.thumbLayer.fillColor = self.thumbFillColor.cgColor
        self.thumbLayer.strokeColor = self.thumbStrokeColor.cgColor
        self.thumbLayer.lineWidth = 0.5
        self.thumbLayer.frame = CGRect(x: 0, y: 0, width: self.thumbDimension, height: self.thumbDimension)
        self.thumbLayer.path = UIBezierPath(ovalIn: self.thumbLayer.bounds).cgPath
        
        // Shadow
        self.thumbLayer.shadowOffset = CGSize(width: 0, height: 2)
        self.thumbLayer.shadowColor = UIColor.black.cgColor
        self.thumbLayer.shadowOpacity = 0.3
        self.thumbLayer.shadowRadius = 2
        self.thumbLayer.contentsScale = UIScreen.main.scale
        
        self.layer.addSublayer(self.thumbLayer)
        
        self.thumbAccessabilityElement = SWStepSliderAccessibilityElement(accessibilityContainer: self, slider: self)
        if let e = self.thumbAccessabilityElement {
            e.accessibilityLabel = "Text Slider"
            e.accessibilityHint = "Increment of decrement to adjust the text size"
            e.accessibilityTraits = UIAccessibilityTraitAdjustable
            self.accessibilityElements = [e]
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        var rect = self.bounds
        rect.origin.x = self.trackOffset
        rect.origin.y = (rect.size.height - self.trackHeight) / 2
        rect.size.height = self.trackHeight
        rect.size.width = self.trackWidth
        self.trackLayer.frame = rect
        
        let center = CGPoint(x: self.trackOffset + CGFloat(self.value) * self.stepWidth, y: self.bounds.midY)
        let thumbRect = CGRect(x: center.x - self.thumbDimension / 2, y: center.y - self.thumbDimension / 2, width: self.thumbDimension, height: self.thumbDimension)
        self.thumbLayer.frame = thumbRect
        if let e = self.thumbAccessabilityElement {
            e.accessibilityFrame = self.convert(thumbRect, to: nil)
            self.accessibilityElements = [e]
        }
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        
        ctx?.saveGState()
        // Draw ticks
        ctx?.setFillColor(self.tickColor.cgColor)
        
        for index in 0..<self.numberOfSteps {
            let x = self.trackOffset + CGFloat(index) * self.stepWidth - 0.5 * self.tickWidth
            let y = self.bounds.midY - 0.5 * self.tickHeight
            
            // Clip the tick
            let tickPath = UIBezierPath(rect: CGRect(x: x , y: y, width: self.tickWidth, height: self.tickHeight))
            
            // Fill the tick
            ctx?.addPath(tickPath.cgPath)
            ctx?.fillPath()
        }
        ctx?.restoreGState()
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: self.thumbDimension * CGFloat(self.numberOfSteps), height: self.thumbDimension)
    }
    
    
    open func setValueAndUpdateView(_ value: Int) {
        self.value = self.clipValue(value)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Update UI without animation
        self.setNeedsLayout()
        CATransaction.commit()
    }
    
    // MARK: - Touch
    
    var previousLocation: CGPoint!
    var dragging = false
    var originalValue: Int!
    
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        self.originalValue = self.value
        
        print("touch \(location)")
        
        if self.thumbLayer.frame.contains(location) {
            self.dragging = true
        } else {
            self.dragging = false
        }
        
        self.previousLocation = location
        
        return self.dragging
    }
    
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        let deltaLocation = location.x - self.previousLocation.x
        let deltaValue = self.deltaValue(deltaLocation)
        
        if deltaLocation < 0 {
            // minus
            self.value = self.clipValue(self.originalValue - deltaValue)
        } else {
            self.value = self.clipValue(self.originalValue + deltaValue)
        }
        
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // Update UI without animation
        self.setNeedsLayout()
        CATransaction.commit()
        

        return true
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        self.previousLocation = nil
        self.originalValue = nil
        self.dragging = false
        
        if self.continuous == false {
            self.sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - Helper
    func deltaValue(_ deltaLocation: CGFloat) -> Int {
        return Int(round(fabs(deltaLocation) / self.stepWidth))
    }
    
    func clipValue(_ value: Int) -> Int {
        return min(max(value, self.minimumValue), self.maximumValue)
    }
    
    // MARK: - Accessibility
    override open var isAccessibilityElement: Bool {
        get {
            return false //return NO to be a container
        }
        set {
            super.isAccessibilityElement = newValue
        }
    }
    
    override open func accessibilityElementCount() -> Int {
        return 1
    }
    
    override open func accessibilityElement(at index: Int) -> Any? {
        return self.thumbAccessabilityElement
    }
    
    override open func index(ofAccessibilityElement element: Any) -> Int {
        return 0
    }
    
    
}
