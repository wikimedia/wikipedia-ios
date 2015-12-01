//
//  MWKTitle+WMFAnalyticsLogging.m
//  Wikipedia
//
//  Created by Corey Floyd on 8/13/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKTitle+WMFAnalyticsLogging.h"
#import "MWKSite+WMFAnalyticsLogging.h"

NS_ASSUME_NONNULL_BEGIN
@implementation MWKTitle (WMFAnalyticsLogging)

- (NSString*)analyticsName {
    NSParameterAssert(self.text);
    NSParameterAssert(self.site);
    if (self.text == nil || self.site == nil) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@/%@", [self.site analyticsName], self.text];
}

@end

NS_ASSUME_NONNULL_END