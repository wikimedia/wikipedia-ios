#import "EditFunnel.h"
#import "SessionSingleton.h"

@implementation EditFunnel

- (id)initWithUserId:(int)userId {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppEdit
    self = [super initWithSchema:@"MobileWikiAppEdit" version:9003125];
    if (self) {
        self.editSessionToken = [self singleUseUUID];
    }
    self.userId = userId;
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[@"editSessionToken"] = self.editSessionToken;
    dict[@"userID"] = @(self.userId);

    //dict[@"pageNS"] = @0; // @todo actually get the namespace...
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - EditFunnel methods

- (void)logStart {
    [self log:@{ @"action": @"start" }];
}

- (void)logPreview {
    [self log:@{ @"action": @"preview" }];
}

- (void)logEditSummaryTap:(NSString *)editSummaryTapped {
    [self log:@{ @"action": @"editSummaryTap",
                 @"editSummaryTapped": editSummaryTapped ? editSummaryTapped : @"" }];
}

- (void)logSavedRevision:(int)revID {
    NSNumber *revIDNumber = [NSNumber numberWithInt:revID];
    [self log:@{ @"action": @"saved",
                 @"revID": (revIDNumber ? revIDNumber : @"") }];
}

- (void)logCaptchaShown {
    [self log:@{ @"action": @"captchaShown" }];
}

- (void)logCaptchaFailure {
    [self log:@{ @"action": @"captchaFailure" }];
}

- (void)logAbuseFilterWarning:(NSString *)name {
    [self log:@{ @"action": @"abuseFilterWarning",
                 @"abuseFilterName": (name ? name : @"") }];
}

- (void)logAbuseFilterError:(NSString *)name {
    [self log:@{ @"action": @"abuseFilterError",
                 @"abuseFilterName": (name ? name : @"") }];
}

- (void)logAbuseFilterWarningIgnore:(NSString *)name {
    [self log:@{ @"action": @"abuseFilterWarningIgnore",
                 @"abuseFilterName": (name ? name : @"") }];
}

- (void)logAbuseFilterWarningBack:(NSString *)name {
    [self log:@{ @"action": @"abuseFilterWarningBack",
                 @"abuseFilterName": (name ? name : @"") }];
}

- (void)logSaveAttempt {
    [self log:@{ @"action": @"saveAttempt" }];
}

- (void)logError:(NSString *)code {
    [self log:@{ @"action": @"error",
                 @"errorText": (code ? code : @"") }];
}

@end
