//
//  LoginFunnel.h
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"

@interface LoginFunnel : EventLoggingFunnel

@property NSString *loginSessionToken;

- (void)logStartFromNavigation;
- (void)logStartFromEdit:(NSString *)editSessionToken;
- (void)logCreateAccountAttempt;
- (void)logCreateAccountFailure;
- (void)logCreateAccountSuccess;
- (void)logError:(NSString *)code;
- (void)logSuccess;

@end
