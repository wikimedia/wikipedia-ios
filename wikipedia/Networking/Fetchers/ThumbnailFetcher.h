//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, ThumbnailFetchErrorType) {
    THUMBNAIL_FETCH_ERROR_UNKNOWN = 0,
    THUMBNAIL_FETCH_ERROR_API = 1,
    THUMBNAIL_FETCH_ERROR_NOT_FOUND = 2
};

@class AFHTTPRequestOperationManager;

@interface ThumbnailFetcher : FetcherBase

@property (nonatomic, strong, readonly) NSString *url;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchThumbnailFromURL: (NSString *)url
                                withManager: (AFHTTPRequestOperationManager *)manager
                         thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
