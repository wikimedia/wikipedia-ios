#import "WMFLoginFunnel.h"

static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kTimestampKey = @"ts";

@implementation WMFLoginFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppLogin
    self = [self initWithSchema:@"MobileWikiAppLogin"
                        version:17836928];
    if (self) {
        self.loginSessionToken = [self singleUseUUID];
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[@"sessionToken"] = self.loginSessionToken;
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kTimestampKey] = self.timestamp;
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - LoginFunnel methods

- (void)logStartFromNavigation {
    [self log:@{@"action": @"start",
                @"source": @"navigation"}];
}

- (void)logStartFromEdit:(NSString *)editSessionToken {
    [self log:@{@"action": @"start",
                @"source": @"edit",
                @"editSessionToken": (editSessionToken ? editSessionToken : @"")}];
}

- (void)logCreateAccountAttempt {
    [self log:@{@"action": @"createAccountAttempt"}];
}

- (void)logCreateAccountFailure {
    [self log:@{@"action": @"createAccountFailure"}];
}

- (void)logCreateAccountSuccess {
    [self log:@{@"action": @"createAccountSuccess"}];
}

- (void)logError:(NSString *)code {
    [self log:@{@"action": @"error",
                @"errorText": (code ? code : @"")}];
}

- (void)logSuccess {
    [self log:@{@"action": @"success"}];
}

@end
