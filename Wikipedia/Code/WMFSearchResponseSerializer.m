#import <WMF/WMFSearchResponseSerializer.h>
#import <WMF/MWKSearchResult.h>

@implementation WMFSearchResponseSerializer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchResultClass = [MWKSearchResult class];
    }
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    NSDictionary *JSON = [super responseObjectForResponse:response data:data error:error];
    NSDictionary *nearbyResultsDictionary = JSON[@"query"][@"pages"];
    NSArray *nearbyResultsArray = [nearbyResultsDictionary allValues];

    return [MTLJSONAdapter modelsOfClass:[self.searchResultClass class] fromJSONArray:nearbyResultsArray error:error];
}

@end
