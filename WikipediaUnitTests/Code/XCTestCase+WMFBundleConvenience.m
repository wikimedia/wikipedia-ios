//
//  XCTestCase+WMFBundleConvenience.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "XCTestCase+WMFBundleConvenience.h"

@implementation XCTestCase (WMFBundleConvenience)

- (NSBundle *)wmf_bundle {
    return [NSBundle bundleForClass:[self class]];
}

@end
