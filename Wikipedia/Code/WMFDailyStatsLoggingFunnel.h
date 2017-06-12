@import WMF.EventLoggingFunnel;

@interface WMFDailyStatsLoggingFunnel : EventLoggingFunnel

@property NSString *appInstallId;

- (void)logAppNumberOfDaysSinceInstall;

@end
