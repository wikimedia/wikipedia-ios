@import WMF;
#import "WMFLogFormatter.h"

static NSString *cachedApplicationName;

@implementation WMFLogFormatter

+ (void)initialize {
    if (self == [WMFLogFormatter class]) {
        cachedApplicationName = [[NSBundle mainBundle] wmf_bundleName];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *level = @"";
    switch (logMessage->_flag) {
        case DDLogFlagVerbose:
            level = @"🗣️ VERBOSE";
            break;
        case DDLogFlagDebug:
            level = @"🐛 DEBUG";
            break;
        case DDLogFlagInfo:
            level = @"ℹ️ INFO";
            break;
        case DDLogFlagWarning:
            level = @"⚠️ WARN";
            break;
        case DDLogFlagError:
            level = @"🚨 ERROR";
            break;
        default:
            break;
    }
    return [NSString stringWithFormat:@"%@ %@[%@] %@#L%lu %@: %@",
                                      [self stringFromDate:logMessage->_timestamp],
                                      cachedApplicationName,
                                      [self queueThreadLabelForLogMessage:logMessage],
                                      logMessage -> _function,
                                      (unsigned long)logMessage -> _line,
                                      level,
                                      logMessage -> _message];
}

@end
