#import <WMF/EventLoggingFunnel.h>

@interface ProtectedEditAttemptFunnel : EventLoggingFunnel

- (id)init;
- (void)logProtectionStatus:(NSString *)protectionStatus;

@end
