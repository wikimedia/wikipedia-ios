@import WMF.EventLoggingFunnel;

@interface WMFLoginFunnel : EventLoggingFunnel

@property NSString *loginSessionToken;

- (void)logStartFromNavigation;
- (void)logStartFromEdit:(NSString *)editSessionToken;
- (void)logCreateAccountAttempt;
- (void)logCreateAccountFailure;
- (void)logCreateAccountSuccess;
- (void)logError:(NSString *)code;
- (void)logSuccess;

@end
