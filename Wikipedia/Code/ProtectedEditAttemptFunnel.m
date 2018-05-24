#import "ProtectedEditAttemptFunnel.h"

static NSString *const kAppInstallIdKey = @"appInstallID";
static NSString *const kTimestampKey = @"ts";

@implementation ProtectedEditAttemptFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppProtectedEditAttempt
    self = [super initWithSchema:@"MobileWikiAppProtectedEditAttempt"
                         version:17836991];
    return self;
}
- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallID;
    dict[kTimestampKey] = self.timestamp;
    return dict;
}

- (void)logProtectionStatus:(NSString *)protectionStatus {
    [self log:@{@"protectionStatus": protectionStatus ? protectionStatus : @""}];
}

@end
