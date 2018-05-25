#import "ProtectedEditAttemptFunnel.h"

@implementation ProtectedEditAttemptFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppProtectedEditAttempt
    self = [super initWithSchema:@"MobileWikiAppProtectedEditAttempt"
                         version:8682497];
    return self;
}

- (void)logProtectionStatus:(NSString *)protectionStatus {
    [self log:@{@"protectionStatus": protectionStatus ? protectionStatus : @""}];
}

@end
