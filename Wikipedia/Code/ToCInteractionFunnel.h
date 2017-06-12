@import WMF.EventLoggingFunnel;

@interface ToCInteractionFunnel : EventLoggingFunnel

@property NSString *appInstallID;

- (id)init;
- (NSDictionary *)preprocessData:(NSDictionary *)eventData;

- (void)logOpen;
- (void)logClose;
- (void)logClick;

@end
