@import Foundation;

@interface MWNetworkActivityIndicatorManager : NSObject

+ (MWNetworkActivityIndicatorManager *)sharedManager;

- (void)push;
- (void)pop;

@end
