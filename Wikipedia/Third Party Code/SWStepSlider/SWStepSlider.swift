//
//  SWStepSlider.swift
//  Pods
//
//  Created by Sarun Wongpatcharapakorn on 2/4/16.
//
//

import WMFComponents

@IBDesignable
open class SWStepSlider: UIControl {
    @IBInspectable open var minimumValue: Int = 0
    @IBInspectable open var maximumValue: Int = 4
    @IBInspectable open var value: Int = 2 {
        didSet {
            if self.value != oldValue && self.continuous {
                self.sendActions(for: .valueChanged)
            }
        }
    }
    
    @IBInspectable open var continuous: Bool = true // if set, value change events are generated any time the value changes due to dragging. default = YES
    
    let trackLayer = CALayer()
    var trackHeight: CGFloat = 1
    var trackColor = WMFColor.gray400

    var tickHeight: CGFloat = 8
    var tickWidth: CGFloat = 1
    var tickColor = WMFColor.gray400

    
    let thumbLayer = CAShapeLayer()
    var thumbFillColor = WMFColor.white
    var thumbStrokeColor = WMFColor.gray200
    var thumbDimension: CGFloat = 28

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
        self.isAccessibilityElement = true
        self.accessibilityTraits = UIAccessibilityTraits.adjustable
        
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
        
        // Tap Gesture Recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tap)
        
        // Reverse the slider if we are in RTL mode
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            self.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        
        self.layer.addSublayer(self.thumbLayer)
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
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        ctx.saveGState()
        // Draw ticks
        ctx.setFillColor(self.tickColor.cgColor)
        
        for index in 0..<self.numberOfSteps {
            let x = self.trackOffset + CGFloat(index) * self.stepWidth - 0.5 * self.tickWidth
            let y = self.bounds.midY - 0.5 * self.tickHeight
            
            // Clip the tick
            let tickPath = UIBezierPath(rect: CGRect(x: x , y: y, width: self.tickWidth, height: self.tickHeight))
            
            // Fill the tick
            ctx.addPath(tickPath.cgPath)
            ctx.fillPath()
        }
        ctx.restoreGState()
    }
    
    open override var intrinsicContentSize : CGSize {
        return CGSize(width: self.thumbDimension * CGFloat(self.numberOfSteps), height: self.thumbDimension)
    }
    
    // MARK: - Touch
    
    var previousLocation: CGPoint!
    var dragging = false
    var originalValue: Int!
    
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        self.originalValue = self.value
        
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

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !(gestureRecognizer is UIPanGestureRecognizer)
    }
    
    // MARK: - Helper
    func deltaValue(_ deltaLocation: CGFloat) -> Int {
        return Int(round(abs(deltaLocation) / self.stepWidth))
    }
    
    func clipValue(_ value: Int) -> Int {
        return min(max(value, self.minimumValue), self.maximumValue)
    }
    
    // MARK: - Tap Gesture Recognizer
    
    @objc func handleTap(_ sender: UIGestureRecognizer) {
        if !self.dragging {
            let pointTapped: CGPoint = sender.location(in: self)
            
            let widthOfSlider: CGFloat = self.bounds.size.width
            let newValue = pointTapped.x * (CGFloat(self.numberOfSteps) / widthOfSlider)
            
            self.value = Int(newValue)
            if self.continuous == false {
                self.sendActions(for: .valueChanged)
            }
            
            self.setNeedsLayout()
        }
    }
    
    // MARK: - Accessibility
    
    open override func accessibilityIncrement() {
        guard self.value < self.maximumValue else {
            return
        }
        self.value = self.value + 1
        if self.continuous == false {
            self.sendActions(for: .valueChanged)
        }
        self.setNeedsLayout()
    }
    
    open override func accessibilityDecrement() {
        guard self.value > self.minimumValue else {
            return
        }
        self.value = self.value - 1
        if self.continuous == false {
            self.sendActions(for: .valueChanged)
        }
        self.setNeedsLayout()
    }
}
