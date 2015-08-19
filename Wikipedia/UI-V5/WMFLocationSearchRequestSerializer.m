
#import "WMFLocationSearchRequestSerializer.h"
@import CoreLocation;

// Reminder: For caching reasons, don't do "(scale * 320)" here.
#define LEAD_IMAGE_WIDTH (([UIScreen mainScreen].scale > 1) ? 640 : 320)

@implementation WMFLocationSearchRequestSerializer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maximumNumberOfResults = 50;
    }
    return self;
}

- (NSString*)maximumNumberOfResultsAsString {
    return [NSString stringWithFormat:@"%lu", (unsigned long)self.maximumNumberOfResults];
}

- (NSURLRequest*)requestBySerializingRequest:(NSURLRequest*)request
                              withParameters:(id)parameters
                                       error:(NSError* __autoreleasing*)error {
    NSDictionary* serializedParams = [self paramsForLocation:(CLLocation*)parameters];
    return [super requestBySerializingRequest:request withParameters:serializedParams error:error];
}

- (NSDictionary*)paramsForLocation:(CLLocation*)location {
    NSString* coords =
        [NSString stringWithFormat:@"%f|%f", location.coordinate.latitude, location.coordinate.longitude];
    return @{
               @"action": @"query",
               @"prop": @"coordinates|pageimages|pageterms",
               @"colimit": [self maximumNumberOfResultsAsString],
               @"pithumbsize": @(LEAD_IMAGE_WIDTH),
               @"pilimit": [self maximumNumberOfResultsAsString],
               @"wbptterms": @"description",
               @"generator": @"geosearch",
               @"ggscoord": coords,
               @"codistancefrompoint": coords,
               @"ggsradius": @"10000",
               @"ggslimit": [self maximumNumberOfResultsAsString],
               @"format": @"json"
    };
}

@end
