//
//  LoginFunnel.m
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "LoginFunnel.h"

@implementation LoginFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppLogin
    self = [self initWithSchema:@"MobileWikiAppLogin"
                        version:8234533];
    if (self) {
        self.loginSessionToken = [self singleUseUUID];
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[@"loginSessionToken"] = self.loginSessionToken;
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - LoginFunnel methods

- (void)logStartFromNavigation {
    [self log:@{ @"action" : @"start",
                 @"source" : @"navigation" }];
}

- (void)logStartFromEdit:(NSString *)editSessionToken {
    [self log:@{ @"action" : @"start",
                 @"source" : @"edit",
                 @"editSessionToken" : (editSessionToken ? editSessionToken : @"") }];
}

- (void)logCreateAccountAttempt {
    [self log:@{ @"action" : @"createAccountAttempt" }];
}

- (void)logCreateAccountFailure {
    [self log:@{ @"action" : @"createAccountFailure" }];
}

- (void)logCreateAccountSuccess {
    [self log:@{ @"action" : @"createAccountSuccess" }];
}

- (void)logError:(NSString *)code {
    [self log:@{ @"action" : @"error",
                 @"errorText" : (code ? code : @"") }];
}

- (void)logSuccess {
    [self log:@{ @"action" : @"success" }];
}

@end
