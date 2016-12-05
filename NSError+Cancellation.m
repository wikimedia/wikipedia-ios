#import "NSError+Cancellation.h"

@implementation NSError (Cancellation)

+ (NSError *)wmf_cancelledError {
    return [NSError errorWithDomain:@"org.wikimedia.error" code:8675309 userInfo:nil];
}

@end
