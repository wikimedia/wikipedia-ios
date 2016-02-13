//
//  WMFMostReadTitleFetcher.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/11/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKSite;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFMostReadTitleFetcherErrorDomain;
extern NSString* const WMFMostReadTitleFetcherErrorFailingDateUserInfoKey;

typedef NS_ENUM (NSInteger, WMFMostReadTitleFetcherError) {
    WMFMostReadTitleFetcherErrorInvalidDate
};

@interface WMFMostReadTitleFetcher : NSObject

- (AnyPromise*)fetchMostReadTitlesForSite:(MWKSite*)site date:(NSDate*)date;

@end

NS_ASSUME_NONNULL_END
