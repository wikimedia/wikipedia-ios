//
//  SavedPagesFunnel.m
//  Wikipedia
//
//  Created by Brion on 7/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "SavedPagesFunnel.h"

static NSString* const kEventDataAssertVerbiage = @"Event data not present";
static NSString* const kAppInstallIdKey         = @"appInstallID";

@implementation SavedPagesFunnel

- (id)init {
    // http://meta.wikimedia.org/wiki/Schema:MobileWikiAppSavedPages
    self = [super initWithSchema:@"MobileWikiAppSavedPages" version:10375480];
    if (self) {
        self.appInstallId = [self persistentUUID:@"ReadingAction"];
    }
    return self;
}

- (void)logSaveNew {
    [self log:@{@"action": @"savenew"}];
}

- (void)logUpdate {
    [self log:@{@"action": @"update"}];
}

- (void)logImportOnSubdomain:(NSString*)subdomain {
    [self log:@{@"action": @"import"}
         wiki:[subdomain stringByAppendingString:@"wiki"]];
}

- (void)logDelete {
    [self log:@{@"action": @"delete"}];
}

- (void)logEditAttempt {
    [self log:@{@"action": @"editattempt"}];
}

// Doesn't seem to be relevant to iOS version?
- (void)logEditRefresh {
    [self log:@{@"action": @"editrefresh"}];
}

// Doesn't seem to be relevant to iOS version?
- (void)logEditAfterRefresh {
    [self log:@{@"action": @"editafterrefresh"}];
}

- (NSDictionary*)preprocessData:(NSDictionary*)eventData {
    if (!eventData) {
        NSAssert(false, @"%@ : %@",
                 kEventDataAssertVerbiage,
                 eventData);
        return nil;
    }
    NSMutableDictionary* dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallId;
    return [dict copy];
}

@end
