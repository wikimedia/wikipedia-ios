#import "WMFSearchResults+ResponseSerializer.h"
#import <WMF/WMFMantleJSONResponseSerializer.h>
#import <WMF/AFNetworking.h>

@implementation WMFSearchResults (ResponseSerializer)

+ (AFHTTPResponseSerializer *)responseSerializer {
    return [WMFMantleJSONResponseSerializer serializerForInstancesOf:self fromKeypath:@"query" emptyValueForJSONKeypathAllowed:YES];
}

@end
