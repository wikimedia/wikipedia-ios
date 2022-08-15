#import "DDLog+WMFLogger.h"
#import "WMFLogFormatter.h"
#import "Wikipedia-Swift.h"

@implementation DDLog (WMFLogger)

+ (void)load {
    [self wmf_addLoggersForCurrentConfiguration];
    [self wmf_setSwiftDefaultLogLevel:LOG_LEVEL_DEF];
}

+ (void)wmf_addLoggersForCurrentConfiguration {
    [self wmf_addWMFFormattedLogger:[BasicLogger new]];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [self wmf_addWMFFormattedLogger:fileLogger];
}

+ (void)wmf_addWMFFormattedLogger:(id<DDLogger>)logger {
    [logger setLogFormatter:[WMFLogFormatter new]];
    [DDLog addLogger:logger];
}

+ (NSString *)wmf_currentLogFilePath {
    DDFileLogger *logger = [[DDLog allLoggers] wmf_match:^BOOL(id obj) {
        return [obj isKindOfClass:[DDFileLogger class]];
    }];

    return [[logger.logFileManager sortedLogFilePaths] firstObject];
}

+ (NSString *)wmf_currentLogFile {
    NSString *logContents = [NSString stringWithContentsOfFile:[self wmf_currentLogFilePath] encoding:NSUTF8StringEncoding error:nil];
    return logContents;
}

@end
