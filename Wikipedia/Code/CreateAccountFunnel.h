//
//  CreateAccountFunnel.h
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "EventLoggingFunnel.h"

@interface CreateAccountFunnel : EventLoggingFunnel

@property NSString *createAccountSessionToken;

- (void)logStartFromLogin:(NSString *)loginSessionToken;
- (void)logSuccess;
- (void)logCaptchaShown;
- (void)logCaptchaFailure;
- (void)logError:(NSString *)code;

@end
