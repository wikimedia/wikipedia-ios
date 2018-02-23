#import "WMFLogFormatter.h"
#import <WMF/NSBundle+WMFInfoUtils.h>

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
            level = @"V";
            break;
        case DDLogFlagDebug:
            level = @"D";
            break;
        case DDLogFlagInfo:
            level = @"I";
            break;
        case DDLogFlagWarning:
            level = @"W";
            break;
        case DDLogFlagError:
            level = @"E";
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
