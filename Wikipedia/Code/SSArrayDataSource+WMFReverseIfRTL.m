//
//  SSArrayDataSource+WMFReverseIfRTL.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/8/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "SSArrayDataSource+WMFReverseIfRTL.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"

@implementation SSArrayDataSource (WMFReverseIfRTL)

- (instancetype)wmf_initWithItemsAndReverseIfNeeded:(NSArray*)items {
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        items = [items wmf_reverseArrayIfApplicationIsRTL];
    }
    return [self initWithItems:items];
}

@end
