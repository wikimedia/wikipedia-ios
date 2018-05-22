@import WMF.EventLoggingFunnel;

@interface WMFDailyStatsLoggingFunnel : EventLoggingFunnel

+ (WMFDailyStatsLoggingFunnel *)shared;

- (void)logAppNumberOfDaysSinceInstall;

@end
