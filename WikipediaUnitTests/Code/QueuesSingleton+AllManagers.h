//
//  QueuesSingleton+AllManagers.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "QueuesSingleton.h"

@interface QueuesSingleton (AllManagers)

- (NSArray<AFHTTPSessionManager *> *)allManagers;

@end
