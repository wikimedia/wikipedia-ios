//
//  WMFSearchFunnel.h
//  Wikipedia
//
//  Created by Corey Floyd on 5/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "EventLoggingFunnel.h"

typedef NS_ENUM(NSUInteger, WMFSearchType) {
    WMFSearchTypePrefix = 0,
    WMFSearchTypeFull
};

@interface WMFSearchFunnel : EventLoggingFunnel

- (void)logSearchStart;
- (void)logSearchAutoSwitch;
- (void)logSearchDidYouMean;
- (void)logSearchResultTap;
- (void)logSearchCancel;

- (void)logSearchResultsWithTypeOfSearch:(WMFSearchType)type resultCount:(NSUInteger)count elapsedTime:(NSTimeInterval)searchTime;

- (void)logShowSearchErrorWithTypeOfSearch:(WMFSearchType)type elapsedTime:(NSTimeInterval)searchTime;

@end
