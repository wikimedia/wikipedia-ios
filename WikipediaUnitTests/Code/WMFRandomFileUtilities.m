//
//  WMFRandomFileUtilities.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFRandomFileUtilities.h"

NSString *WMFRandomTemporaryPath() {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
}

NSString *WMFRandomTemporaryFileOfType(NSString *extension) {
    return [WMFRandomTemporaryPath() stringByAppendingPathExtension:extension];
}