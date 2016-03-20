//
//  UINavigationController+History.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/01/12.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit

extension UINavigationController {
    public weak var historyDelegate: SAHistoryNavigationViewControllerDelegate? {
        set {
            willSetHistoryDelegate(newValue)
        }
        get {
            return willGetHistoryDelegate()
        }
    }
    public func showHistory() {}
    public func setHistoryBackgroundColor(color: UIColor) {}
    public func contentView() -> UIView? { return nil }
    func willSetHistoryDelegate(delegate: SAHistoryNavigationViewControllerDelegate?) {}
    func willGetHistoryDelegate() -> SAHistoryNavigationViewControllerDelegate? { return nil }
}