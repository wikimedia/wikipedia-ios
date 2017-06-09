#import <WMF/WMFLogging.h>

@interface DDLog (WMFLogger)

+ (void)wmf_addLoggersForCurrentConfiguration;

+ (NSString *)wmf_currentLogFile;

@end
