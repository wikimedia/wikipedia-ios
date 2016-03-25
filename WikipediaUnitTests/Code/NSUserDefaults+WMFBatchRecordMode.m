//
//  NSUserDefaults+WMFBatchRecordMode.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSUserDefaults+WMFBatchRecordMode.h"

@implementation NSUserDefaults (WMFBatchRecordMode)

- (BOOL)wmf_visualTestBatchRecordMode {
    return [self boolForKey:@"WMFVisualTestBatchRecordMode"];
}

@end
