//
//  ProtectedEditAttemptFunnel.h
//  Wikipedia
//
//  Created by Brion on 6/6/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"

@interface ProtectedEditAttemptFunnel : EventLoggingFunnel

- (id)init;
- (void)logProtectionStatus:(NSString *)protectionStatus;

@end
