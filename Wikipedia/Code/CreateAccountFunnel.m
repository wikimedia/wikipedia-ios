//
//  CreateAccountFunnel.m
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "CreateAccountFunnel.h"

@implementation CreateAccountFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppCreateAccount
    self = [self initWithSchema:@"MobileWikiAppCreateAccount"
                        version:8240702];
    if (self) {
        self.createAccountSessionToken = [self singleUseUUID];
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[@"createAccountSessionToken"] = self.createAccountSessionToken;
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - CreateAccountFunnel methods

- (void)logStartFromLogin:(NSString *)loginSessionToken {
    [self log:@{ @"action" : @"start",
                 @"loginSessionToken" : (loginSessionToken ? loginSessionToken : @"") }];
}

- (void)logSuccess {
    [self log:@{ @"action" : @"success" }];
}

- (void)logCaptchaShown {
    [self log:@{ @"action" : @"captchaShown" }];
}

- (void)logCaptchaFailure {
    [self log:@{ @"action" : @"captchaFailure" }];
}

- (void)logError:(NSString *)code {
    [self log:@{ @"action" : @"error",
                 @"errorText" : (code ? code : @"") }];
}

@end
