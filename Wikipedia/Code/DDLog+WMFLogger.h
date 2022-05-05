@import WMF.WMFLogging;

@interface DDLog (WMFLogger)

+ (void)wmf_addLoggersForCurrentConfiguration;

+ (NSString *)wmf_currentLogFile;
+ (NSString *)wmf_currentLogFilePath;

@end
