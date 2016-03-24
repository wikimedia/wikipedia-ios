//
//  UIViewController+Screenshot.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/01/12.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//


import UIKit

extension UIViewController {
    func screenshotFromWindow(scale: CGFloat = 0.0) -> UIImage? {
        guard let window = UIApplication.sharedApplication().windows.first else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, scale)
        window.drawViewHierarchyInRect(window.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}