
#import "NSError+WMFExtensions.h"

NSString* const WMFErrorDomain = @"WMFErrorDomain";

@implementation NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo{
    
    return [NSError errorWithDomain:WMFErrorDomain code:type userInfo:userInfo];
}

@end
