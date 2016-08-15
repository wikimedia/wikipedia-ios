//
//  ReadingActionFunnel.m
//  Wikipedia
//
//  Created by Brion on 5/28/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "ReadingActionFunnel.h"

@implementation ReadingActionFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppReadingAction
    self = [super initWithSchema:@"MobileWikiAppReadingAction" version:8233801];
    if (self) {
        self.appInstallID = [self persistentUUID:@"ReadingAction"];
    }
    return self;
}

- (void)logSomethingHappened {
    NSNumber *number = [NSNumber numberWithLong:time(NULL)];
    [self log:@{ @"appInstallReadActionID" : self.appInstallID,
                 @"clientSideTS" : (number ? number : @"") }];
}

@end
