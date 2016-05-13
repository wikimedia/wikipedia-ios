//
//  LoggingDefaults.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift

extension DDLog {
    public class func wmf_setSwiftDefaultLogLevel(level: UInt) {
        defaultDebugLevel = DDLogLevel(rawValue: level)!
    }
}
