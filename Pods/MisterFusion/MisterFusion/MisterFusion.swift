//
//  MisterFusion.swift
//  MisterFusion
//
//  Created by Taiki Suzuki on 2015/11/13.
//  Copyright © 2015年 Taiki Suzuki. All rights reserved.
//

import UIKit

public class MisterFusion: NSObject {
    private let item: UIView?
    private let attribute: NSLayoutAttribute?
    private let relatedBy: NSLayoutRelation?
    private let toItem: UIView?
    private let toAttribute: NSLayoutAttribute?
    private let multiplier: CGFloat?
    private let constant: CGFloat?
    private let priority: UILayoutPriority?
    private let horizontalSizeClass: UIUserInterfaceSizeClass?
    private let verticalSizeClass: UIUserInterfaceSizeClass?
    
    override public var description: String {
        return "\(super.description)\n" +
               "item               : \(item)\n" +
               "attribute          : \(attribute?.rawValue))\n" +
               "relatedBy          : \(relatedBy?.rawValue))\n" +
               "toItem             : \(toItem)\n" +
               "toAttribute        : \(toAttribute?.rawValue))\n" +
               "multiplier         : \(multiplier)\n" +
               "constant           : \(constant)\n" +
               "priority           : \(priority)\n" +
               "horizontalSizeClass: \(horizontalSizeClass?.rawValue)\n" +
               "verticalSizeClass  : \(verticalSizeClass?.rawValue)\n"
    }
    
    init(item: UIView?, attribute: NSLayoutAttribute?, relatedBy: NSLayoutRelation?, toItem: UIView?, toAttribute: NSLayoutAttribute?, multiplier: CGFloat?, constant: CGFloat?, priority: UILayoutPriority?, horizontalSizeClass: UIUserInterfaceSizeClass?, verticalSizeClass: UIUserInterfaceSizeClass?) {
        self.item = item
        self.attribute = attribute
        self.relatedBy = relatedBy
        self.toItem = toItem
        self.toAttribute = toAttribute
        self.multiplier = multiplier
        self.constant = constant
        self.priority = priority
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
        super.init()
    }
    
    public var Equal: MisterFusion -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |==| $0
        }
    }
    
    public var LessThanOrEqual: MisterFusion -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |<=| $0
        }
    }
    
    public var NotRelatedLessThanOrEqualConstant: CGFloat -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |<=| $0
        }
    }
    
    public var GreaterThanOrEqual: MisterFusion -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |>=| $0
        }
    }
    
    public var NotRelatedGreaterThanOrEqualConstant: CGFloat -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |>=| $0
        }
    }
    
    public var Multiplier: CGFloat -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |*| $0
        }
    }
    
    public var Constant: CGFloat -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |+| $0
        }
    }
    
    public var Priority: UILayoutPriority -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |<>| $0
        }
    }
    
    public var NotRelatedConstant: CGFloat -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me |=| $0
        }
    }
    
    public var HorizontalSizeClass: UIUserInterfaceSizeClass -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me <-> $0
        }
    }
    
    public var VerticalSizeClass: UIUserInterfaceSizeClass -> MisterFusion? {
        return { [weak self] in
            guard let me = self else { return nil }
            return me <|> $0
        }
    }
}

infix operator |==| { associativity left precedence 100 }
public func |==| (left: MisterFusion, right: MisterFusion) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .Equal, toItem: right.item, toAttribute: right.attribute, multiplier: nil, constant: nil, priority: nil, horizontalSizeClass: nil, verticalSizeClass: nil)
}

infix operator |<=| { associativity left precedence 100 }
public func |<=| (left: MisterFusion, right: MisterFusion) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .LessThanOrEqual, toItem: right.item, toAttribute: right.attribute, multiplier: nil, constant: nil, priority: nil, horizontalSizeClass: nil, verticalSizeClass: nil)
}

public func |<=| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .LessThanOrEqual, toItem: nil, toAttribute: .NotAnAttribute, multiplier: nil, constant: right, priority: nil, horizontalSizeClass: nil, verticalSizeClass: nil)
}

infix operator |>=| { associativity left precedence 100 }
public func |>=| (left: MisterFusion, right: MisterFusion) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .GreaterThanOrEqual, toItem: right.item, toAttribute: right.attribute, multiplier: nil, constant: nil, priority: nil, horizontalSizeClass: nil, verticalSizeClass: nil)
}

public func |>=| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .GreaterThanOrEqual, toItem: nil, toAttribute: .NotAnAttribute, multiplier: nil, constant: right, priority: nil, horizontalSizeClass: nil, verticalSizeClass: nil)
}

infix operator |+| { associativity left precedence 100 }
public func |+| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: left.relatedBy, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: left.multiplier, constant: right, priority: left.priority, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: left.verticalSizeClass)
}

infix operator |-| { associativity left precedence 100 }
public func |-| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: left.relatedBy, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: left.multiplier, constant: -right, priority: left.priority, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: left.verticalSizeClass)
}

infix operator |*| { associativity left precedence 100 }
public func |*| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: left.relatedBy, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: right, constant: left.constant, priority: left.priority, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: left.verticalSizeClass)
}

infix operator |/| { associativity left precedence 100 }
public func |/| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: left.relatedBy, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: 1 / right, constant: left.constant, priority: left.priority, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: left.verticalSizeClass)
}

infix operator |<>| { associativity left precedence 100 }
public func |<>| (left: MisterFusion, right: UILayoutPriority) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: left.relatedBy, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: left.multiplier, constant: left.constant, priority: right, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: left.verticalSizeClass)
}

infix operator |=| { associativity left precedence 100 }
public func |=| (left: MisterFusion, right: CGFloat) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .Equal, toItem: nil, toAttribute: .NotAnAttribute, multiplier: left.multiplier, constant: right, priority: left.priority, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: left.verticalSizeClass)
}

infix operator <-> { associativity left precedence 100 }
public func <-> (left: MisterFusion, right: UIUserInterfaceSizeClass) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .Equal, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: left.multiplier, constant: left.constant, priority: left.priority, horizontalSizeClass: right, verticalSizeClass: left.verticalSizeClass)
}

infix operator <|> { associativity left precedence 100 }
public func <|> (left: MisterFusion, right: UIUserInterfaceSizeClass) -> MisterFusion {
    return MisterFusion(item: left.item, attribute: left.attribute, relatedBy: .Equal, toItem: left.toItem, toAttribute: left.toAttribute, multiplier: left.multiplier, constant: left.constant, priority: left.priority, horizontalSizeClass: left.horizontalSizeClass, verticalSizeClass: right)
}

extension UIView {
    public var Top: MisterFusion { return createMisterFusion(.Top) }
    
    public var Right: MisterFusion { return createMisterFusion(.Right) }
    
    public var Left: MisterFusion { return createMisterFusion(.Left) }
    
    public var Bottom: MisterFusion { return createMisterFusion(.Bottom) }
    
    public var Height: MisterFusion { return createMisterFusion(.Height) }
    
    public var Width: MisterFusion { return createMisterFusion(.Width) }
    
    public var Leading: MisterFusion { return createMisterFusion(.Leading) }
    
    public var Trailing: MisterFusion { return createMisterFusion(.Trailing) }
    
    public var CenterX: MisterFusion { return createMisterFusion(.CenterX) }
    
    public var CenterY: MisterFusion { return createMisterFusion(.CenterY) }
    
    public var Baseline: MisterFusion { return createMisterFusion(.Baseline) }
    
    public var LastBaseline: MisterFusion { return createMisterFusion(.LastBaseline) }
    
    public var NotAnAttribute: MisterFusion { return createMisterFusion(.NotAnAttribute) }
    
    @available(iOS 8.0, *)
    public var LeftMargin: MisterFusion { return createMisterFusion(.LeftMargin) }
    
    @available(iOS 8.0, *)
    public var RightMargin: MisterFusion { return createMisterFusion(.RightMargin) }
    
    @available(iOS 8.0, *)
    public var TopMargin: MisterFusion { return createMisterFusion(.TopMargin) }
    
    @available(iOS 8.0, *)
    public var BottomMargin: MisterFusion { return createMisterFusion(.BottomMargin) }
    
    @available(iOS 8.0, *)
    public var LeadingMargin: MisterFusion { return createMisterFusion(.LeadingMargin) }
    
    @available(iOS 8.0, *)
    public var TrailingMargin: MisterFusion { return createMisterFusion(.TrailingMargin) }
    
    @available(iOS 8.0, *)
    public var CenterXWithinMargins: MisterFusion { return createMisterFusion(.CenterXWithinMargins) }
    
    @available(iOS 8.0, *)
    public var CenterYWithinMargins: MisterFusion { return createMisterFusion(.CenterYWithinMargins) }
    
    private func createMisterFusion(attribute: NSLayoutAttribute) -> MisterFusion {
        return MisterFusion(item: self, attribute: attribute, relatedBy: nil, toItem: nil, toAttribute: nil, multiplier: nil, constant: nil, priority: nil, horizontalSizeClass: nil, verticalSizeClass: nil)
    }
    
    public func addLayoutConstraint(misterFusion: MisterFusion) -> NSLayoutConstraint? {
        let item: UIView = misterFusion.item ?? self
        let traitCollection = UIApplication.sharedApplication().keyWindow?.traitCollection
        if let horizontalSizeClass = misterFusion.horizontalSizeClass
            where horizontalSizeClass != traitCollection?.horizontalSizeClass {
            return nil
        }
        if let verticalSizeClass = misterFusion.verticalSizeClass
            where verticalSizeClass != traitCollection?.verticalSizeClass {
            return nil
        }
        let attribute: NSLayoutAttribute = misterFusion.attribute ?? .NotAnAttribute
        let relatedBy: NSLayoutRelation = misterFusion.relatedBy ?? .Equal
        let toAttribute: NSLayoutAttribute = misterFusion.toAttribute ?? attribute
        let toItem: UIView? = toAttribute == .NotAnAttribute ? nil : misterFusion.toItem ?? self
        let multiplier: CGFloat = misterFusion.multiplier ?? 1
        let constant: CGFloat = misterFusion.constant ?? 0
        let constraint = NSLayoutConstraint(item: item, attribute: attribute, relatedBy: relatedBy, toItem: toItem, attribute: toAttribute, multiplier: multiplier, constant: constant)
        constraint.priority = misterFusion.priority ?? UILayoutPriorityRequired
        addConstraint(constraint)
        return constraint
    }
    
    public func addLayoutConstraints(misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        return misterFusions.map { addLayoutConstraint($0) }.filter { $0 != nil }.map { $0! }
    }
    
    public func addLayoutConstraints(misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return addLayoutConstraints(misterFusions)
    }
    
    public func addLayoutSubview(subview: UIView, andConstraint misterFusion: MisterFusion) -> NSLayoutConstraint? {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        return addLayoutConstraint(misterFusion)
    }
    
    public func addLayoutSubview(subview: UIView, andConstraints misterFusions: [MisterFusion]) -> [NSLayoutConstraint] {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        return addLayoutConstraints(misterFusions)
    }
    
    public func addLayoutSubview(subview: UIView, andConstraints misterFusions: MisterFusion...) -> [NSLayoutConstraint] {
        return addLayoutSubview(subview, andConstraints: misterFusions)
    }
}