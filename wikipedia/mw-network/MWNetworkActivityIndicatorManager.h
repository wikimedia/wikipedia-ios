//  Created by Felix Mo on 2013-01-30.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@interface MWNetworkActivityIndicatorManager : NSObject

+ (MWNetworkActivityIndicatorManager *)sharedManager;

- (void)push;
- (void)pop;

@end
