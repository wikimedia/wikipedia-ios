
#import <AFNetworking/AFURLRequestSerialization.h>

@interface WMFLocationSearchRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, assign) NSUInteger maximumNumberOfResults;

@end
