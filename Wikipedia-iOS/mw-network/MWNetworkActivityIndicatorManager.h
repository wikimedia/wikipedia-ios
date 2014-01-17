//  Created by Felix Mo on 2013-01-30.

@interface MWNetworkActivityIndicatorManager : NSObject

+ (MWNetworkActivityIndicatorManager *)sharedManager;

- (void)push;
- (void)pop;

@end
