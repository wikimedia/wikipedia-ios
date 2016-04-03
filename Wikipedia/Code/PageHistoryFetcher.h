//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

@class AFHTTPSessionManager;

@interface PageHistoryFetcher : NSObject

@property (nonatomic, assign, readonly) BOOL isFetching;
- (AnyPromise*)fetchRevisionInfoForTitle:(MWKTitle*)title;

@end
