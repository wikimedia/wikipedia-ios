//
//  SWStepSlider.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 2/4/16.
//
//

import UIKit

public class SWStepSliderAccessibilityElement: UIAccessibilityElement {
    var minimumValue: Int = 0
    var maximumValue: Int = 4
    var value: Int = 2
    
    weak var slider: SWStepSlider?
    
    public init(accessibilityContainer container: AnyObject, slider: SWStepSlider) {
        self.slider = slider
        super.init(accessibilityContainer: container)
    }

    override public func accessibilityActivate() -> Bool {
        return true
    }
    
    override public func accessibilityIncrement() {
        let new = value + 1
        self.slider?.setValueAndUpdateView(new)
    }
    
    override public func accessibilityDecrement() {
        let new = value - 1
        self.slider?.setValueAndUpdateView(new)
    }
}



@IBDesignable
public class SWStepSlider: UIControl {
    @IBInspectable public var minimumValue: Int = 0 {
        didSet {
            if self.minimumValue != oldValue {
                if let e = self.thumbAccessabilityElement {
                    e.minimumValue = self.minimumValue
                    self.accessibilityElements = [e]
                }
            }
        }
    }
    @IBInspectable public var maximumValue: Int = 4 {
        didSet {
            if self.maximumValue != oldValue {
                if let e = self.thumbAccessabilityElement {
                    e.minimumValue = self.maximumValue
                    self.accessibilityElements = [e]
                }
            }
        }
    }
    @IBInspectable public var value: Int = 2 {
        didSet {
            if self.value != oldValue {
                if let e = self.thumbAccessabilityElement {
                    e.accessibilityValue = String(self.value)
                    e.value = self.value
                    self.accessibilityElements = [e]
                }
                if self.continuous {
                    self.sendActionsForControlEvents(.ValueChanged)
                }
            }
        }
    }
    
    @IBInspectable public var continuous: Bool = true // if set, value change events are generated any time the value changes due to dragging. default = YES
    
    let trackLayer = CALayer()
    public var trackHeight: CGFloat = 2
    public var trackColor = UIColor(red: 152.0/255.0, green: 152.0/255.0, blue: 152.0/255.0, alpha: 1)
    
    public var tickHeight: CGFloat = 8
    public var tickWidth: CGFloat = 2
    public var tickColor = UIColor(red: 152.0/255.0, green: 152.0/255.0, blue: 152.0/255.0, alpha: 1)
    
    let thumbLayer = CAShapeLayer()
    var thumbFillColor = UIColor.whiteColor()
    var thumbStrokeColor = UIColor(red: 222.0/255.0, green: 222.0/255.0, blue: 222.0/255.0, alpha: 1)
    var thumbDimension: CGFloat = 28

    private var thumbAccessabilityElement: SWStepSliderAccessibilityElement?

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
    
    private func commonInit() {
        self.trackLayer.backgroundColor = self.trackColor.CGColor
        self.layer.addSublayer(trackLayer)
        
        self.thumbLayer.backgroundColor = UIColor.clearColor().CGColor
        self.thumbLayer.fillColor = self.thumbFillColor.CGColor
        self.thumbLayer.strokeColor = self.thumbStrokeColor.CGColor
        self.thumbLayer.lineWidth = 0.5
        self.thumbLayer.frame = CGRect(x: 0, y: 0, width: self.thumbDimension, height: self.thumbDimension)
        self.thumbLayer.path = UIBezierPath(ovalInRect: self.thumbLayer.bounds).CGPath
        
        // Shadow
        self.thumbLayer.shadowOffset = CGSize(width: 0, height: 2)
        self.thumbLayer.shadowColor = UIColor.blackColor().CGColor
        self.thumbLayer.shadowOpacity = 0.3
        self.thumbLayer.shadowRadius = 2
        self.thumbLayer.contentsScale = UIScreen.mainScreen().scale
        
        self.layer.addSublayer(self.thumbLayer)
        
        self.thumbAccessabilityElement = SWStepSliderAccessibilityElement(accessibilityContainer: self, slider: self)
        if let e = self.thumbAccessabilityElement {
            e.accessibilityLabel = "Text Slider"
            e.accessibilityHint = "Increment of decrement to adjust the text size"
            e.accessibilityTraits = UIAccessibilityTraitAdjustable
            self.accessibilityElements = [e]
        }
    }
    
    public override func layoutSubviews() {
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
            e.accessibilityFrame = self.convertRect(thumbRect, toView: nil)
            self.accessibilityElements = [e]
        }
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        
        CGContextSaveGState(ctx)
        // Draw ticks
        CGContextSetFillColorWithColor(ctx, self.tickColor.CGColor)
        
        for index in 0..<self.numberOfSteps {
            let x = self.trackOffset + CGFloat(index) * self.stepWidth - 0.5 * self.tickWidth
            let y = self.bounds.midY - 0.5 * self.tickHeight
            
            // Clip the tick
            let tickPath = UIBezierPath(rect: CGRect(x: x , y: y, width: self.tickWidth, height: self.tickHeight))
            
            // Fill the tick
            CGContextAddPath(ctx, tickPath.CGPath)
            CGContextFillPath(ctx)
        }
        CGContextRestoreGState(ctx)
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: self.thumbDimension * CGFloat(self.numberOfSteps), height: self.thumbDimension)
    }
    
    
    public func setValueAndUpdateView(value: Int) {
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
    
    public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
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
    
    public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
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
    
    public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        self.previousLocation = nil
        self.originalValue = nil
        self.dragging = false
        
        if self.continuous == false {
            self.sendActionsForControlEvents(.ValueChanged)
        }
    }
    
    // MARK: - Helper
    func deltaValue(deltaLocation: CGFloat) -> Int {
        return Int(round(fabs(deltaLocation) / self.stepWidth))
    }
    
    func clipValue(value: Int) -> Int {
        return min(max(value, self.minimumValue), self.maximumValue)
    }
    
    // MARK: - Accessibility
    override public var isAccessibilityElement: Bool {
        get {
            return false //return NO to be a container
        }
        set {
            super.isAccessibilityElement = newValue
        }
    }
    
    override public func accessibilityElementCount() -> Int {
        return 1
    }
    
    override public func accessibilityElementAtIndex(index: Int) -> AnyObject? {
        return self.thumbAccessabilityElement
    }
    
    override public func indexOfAccessibilityElement(element: AnyObject) -> Int {
        return 0
    }
    
    
}
