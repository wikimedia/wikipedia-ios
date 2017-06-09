#import <WMF/EventLoggingFunnel.h>

@interface WMFDailyStatsLoggingFunnel : EventLoggingFunnel

@property NSString *appInstallId;

- (void)logAppNumberOfDaysSinceInstall;

@end
