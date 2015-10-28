//
//  UIViewController+SafePreviewing.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 10/27/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

extension UIViewController {
    public var wmf_isForceTouchAvailable: Bool {
        get {
            if #available(iOS 9, *) {
                return self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available
            } else {
                return false
            }
        }
    }
}
