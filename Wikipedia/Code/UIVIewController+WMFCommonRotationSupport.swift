//
//  UIVIewController+WMFCommonRotationSupport.swift
//  Wikipedia
//
//  Created by Corey Floyd on 4/4/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

import UIKit

public extension UIViewController {
    public func wmf_orientationMaskPortraitiPhoneAnyiPad() -> UIInterfaceOrientationMask{
        if(UI_USER_INTERFACE_IDIOM() == .Pad){
            return .All;
        }else{
            return .Portrait;
        }
    }
}