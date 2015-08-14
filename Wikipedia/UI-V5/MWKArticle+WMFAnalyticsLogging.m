//
//  MWKArticle+WMFAnalyticsLogging.m
//  Wikipedia
//
//  Created by Corey Floyd on 8/13/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKArticle+WMFAnalyticsLogging.h"
#import "MWKTitle+WMFAnalyticsLogging.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKArticle (WMFAnalyticsLogging)

- (NSString*)analyticsName {
    return [self.title analyticsName];
}

@end

NS_ASSUME_NONNULL_END