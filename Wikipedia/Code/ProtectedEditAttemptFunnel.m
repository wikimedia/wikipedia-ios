#import "ProtectedEditAttemptFunnel.h"

@implementation ProtectedEditAttemptFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppProtectedEditAttempt
    self = [super initWithSchema:@"MobileWikiAppProtectedEditAttempt"
                         version:8682497];
    if (self) {
        self.requiresAppInstallID = NO;
    }
    return self;
}

- (void)logProtectionStatus:(NSString *)protectionStatus {
    [self log:@{@"protectionStatus": protectionStatus ? protectionStatus : @""}];
}

@end
