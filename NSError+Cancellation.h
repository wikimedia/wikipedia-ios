#import <Foundation/Foundation.h>

@interface NSError (Cancellation)

+ (NSError *)wmf_cancelledError;

@end
