//
//  UIView+Screenshot.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/01/12.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit

extension UIView {
    func screenshotImage(scale: CGFloat = 0.0) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
        drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}