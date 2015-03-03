//
//  WMFDebugViewController+EnabledFeatures.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFDebugViewController+EnabledFeatures.h"
#import "WMFCrashReportingDebugFeature.h"
#import <BlocksKit/BlocksKit.h>

@implementation WMFDebugViewController (EnabledFeatures)

+ (NSArray*)enabledFeatures
{
    return [@[
      [WMFCrashReportingDebugFeature new]
    ] bk_select:^BOOL(id<WMFDebugFeature> feature) {
        return [feature isEnabled];
    }];
}

- (instancetype)init
{
    return [self initWithFeatures:[WMFDebugViewController enabledFeatures]];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _features = [WMFDebugViewController enabledFeatures];
    }
    return self;
}

@end
