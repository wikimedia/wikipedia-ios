
#import "WMFLocationSearchResponseSerializer.h"
#import <Mantle/Mantle.h>
#import "MWKLocationSearchResult.h"

@implementation WMFLocationSearchResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse*)response
                           data:(NSData*)data
                          error:(NSError* __autoreleasing*)error {
    NSDictionary* JSON                    = [super responseObjectForResponse:response data:data error:error];
    NSDictionary* nearbyResultsDictionary = JSON[@"query"][@"pages"];
    NSArray* nearbyResultsArray           = [nearbyResultsDictionary allValues];

    NSArray* results = [MTLJSONAdapter modelsOfClass:[MWKLocationSearchResult class] fromJSONArray:nearbyResultsArray error:error];
    return [results sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:WMF_SAFE_KEYPATH([MWKLocationSearchResult new], distanceFromQueryCoordinates) ascending:YES]]];
}

@end
