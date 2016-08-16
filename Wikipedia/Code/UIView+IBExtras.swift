//  Created by Monte Hurd on 9/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

import UIKit

/*
Note: as of Xcode 7.0 extensions ignore "@IBDesignable".
So for now to see changes to these parameters update live in
interface builder you need to add "@IBDesignable" to custom subclasses.
*/
extension UIView {
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(CGColor:layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.CGColor
        }
    }

    @IBInspectable var masksToBounds: Bool {
        get {
            return layer.masksToBounds
        }
        set {
            layer.masksToBounds = newValue
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable var shadowColor: UIColor {
        get {
            return UIColor(CGColor:layer.shadowColor!)
        }
        set {
            layer.shadowColor = newValue.CGColor
        }
    }

    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }

    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }

    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }

}