#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (WMFNetworkConnectionError)

- (BOOL)wmf_isNetworkConnectionError;
- (BOOL)wmf_isCancelledError;

@end

NS_ASSUME_NONNULL_END
