//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, NearbyFetchErrorType) {
    NEARBY_FETCH_ERROR_UNKNOWN = 0,
    NEARBY_FETCH_ERROR_API = 1,
    NEARBY_FETCH_ERROR_NO_RESULTS = 2
};

@class AFHTTPRequestOperationManager;

@interface NearbyFetcher : FetcherBase

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
-(instancetype)initAndFetchNearbyForLatitude: (CLLocationDegrees)latitude
                                   longitude: (CLLocationDegrees)longitude
                                 withManager: (AFHTTPRequestOperationManager *)manager
                          thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
