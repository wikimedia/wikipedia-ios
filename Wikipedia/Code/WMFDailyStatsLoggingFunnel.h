@import WMF.EventLoggingFunnel;

@interface WMFDailyStatsLoggingFunnel : EventLoggingFunnel

- (void)logAppNumberOfDaysSinceInstall;

@end
