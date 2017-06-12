#import <WMF/EventLoggingFunnel.h>

@interface ReadingActionFunnel : EventLoggingFunnel

@property NSString *appInstallID;

/**
 * Note this method is not actually used; the appInstallID key is instead
 * sent with the 'action=mobileview' API request on a fresh page read.
 */
- (void)logSomethingHappened;

@end
