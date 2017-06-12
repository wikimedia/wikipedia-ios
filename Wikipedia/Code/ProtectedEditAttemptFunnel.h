@import WMF.EventLoggingFunnel;

@interface ProtectedEditAttemptFunnel : EventLoggingFunnel

- (id)init;
- (void)logProtectionStatus:(NSString *)protectionStatus;

@end
