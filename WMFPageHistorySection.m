//
//  WMFPageHistorySection.m
//  Wikipedia
//
//  Created by Nick DiStefano on 4/3/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFPageHistorySection.h"

@implementation WMFPageHistorySection

- (instancetype)init {
    self = [super init];
    if (self) {
        self.items = @[].mutableCopy;
    }
    return self;
}

@end
