#import "CreateAccountFunnel.h"

static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kTimestampKey = @"ts";

@implementation CreateAccountFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppCreateAccount
    self = [self initWithSchema:@"MobileWikiAppCreateAccount"
                        version:17836914];
    if (self) {
        self.createAccountSessionToken = [self singleUseUUID];
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[@"sessionToken"] = self.createAccountSessionToken;
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kTimestampKey] = self.timestamp;
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - CreateAccountFunnel methods

- (void)logStartFromLogin:(NSString *)loginSessionToken {
    [self log:@{@"action": @"start",
                @"loginSessionToken": (loginSessionToken ? loginSessionToken : @"")}];
}

- (void)logSuccess {
    [self log:@{@"action": @"success"}];
}

- (void)logCaptchaShown {
    [self log:@{@"action": @"captchaShown"}];
}

- (void)logCaptchaFailure {
    [self log:@{@"action": @"captchaFailure"}];
}

- (void)logError:(NSString *)code {
    [self log:@{@"action": @"error",
                @"errorText": (code ? code : @"")}];
}

@end
