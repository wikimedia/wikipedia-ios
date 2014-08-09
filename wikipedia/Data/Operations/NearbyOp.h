//  Created by Monte Hurd on 8/8/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"
#import <CoreLocation/CoreLocation.h>

@interface NearbyOp : MWNetworkOp

- (id)initWithLatitude: (CLLocationDegrees)latitude
             longitude: (CLLocationDegrees)longitude
       completionBlock: (void (^)(NSArray *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
