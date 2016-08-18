#import "WMFSearchResults.h"
@class AFHTTPResponseSerializer;

@interface WMFSearchResults (ResponseSerializer)

+ (AFHTTPResponseSerializer *)responseSerializer;

@end
