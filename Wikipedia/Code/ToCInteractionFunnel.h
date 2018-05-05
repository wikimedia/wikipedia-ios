@import WMF.EventLoggingFunnel;

@interface ToCInteractionFunnel : EventLoggingFunnel

- (id)init;

- (void)logOpen;
- (void)logClose;
- (void)logClick;

@end
