@import WMF.EventLoggingFunnel;

@interface CreateAccountFunnel : EventLoggingFunnel

@property NSString *createAccountSessionToken;

- (void)logStartFromLogin:(NSString *)loginSessionToken;
- (void)logSuccess;
- (void)logCaptchaShown;
- (void)logCaptchaFailure;
- (void)logError:(NSString *)code;

@end
