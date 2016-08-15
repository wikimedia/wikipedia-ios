//
//  ProtectedEditAttemptFunnel.m
//  Wikipedia
//
//  Created by Brion on 6/6/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "ProtectedEditAttemptFunnel.h"

@implementation ProtectedEditAttemptFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppProtectedEditAttempt
    self = [super initWithSchema:@"MobileWikiAppProtectedEditAttempt"
                         version:8682497];
    return self;
}

- (void)logProtectionStatus:(NSString *)protectionStatus {
    [self log:@{ @"protectionStatus" : protectionStatus ? protectionStatus : @"" }];
}

@end
