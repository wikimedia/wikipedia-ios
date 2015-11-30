//
//  UIViewController+SafePreviewing.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 10/27/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation

extension UIViewController {
    public func wmf_ifForceTouchAvailable(then: Void->Void, unavailable: Void->Void) {
        guard #available(iOS 9, *) else {
            return
        }
        if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            then()
        } else {
            unavailable()
        }
    }
}
