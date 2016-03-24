//
//  SAThirdDimensionalTouchRecognizer.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/10/27.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit.UIGestureRecognizerSubclass
import AudioToolbox.AudioServices

@available(iOS 9, *)
class SAThirdDimensionalTouchRecognizer: UILongPressGestureRecognizer {
    private(set) var percentage: CGFloat = 0
    var threshold: CGFloat = 1
    
    init(target: AnyObject?, action: Selector, threshold: CGFloat) {
        self.threshold = threshold
        super.init(target: target, action: action)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        
        guard let touch = touches.first else {
            return
        }
        percentage = max(0, min(1, touch.force / touch.maximumPossibleForce))
        if percentage > threshold && state == .Changed {
            state = .Ended
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        state = .Failed
    }
    
    override func reset() {
        super.reset()
        percentage = 0
    }
}
