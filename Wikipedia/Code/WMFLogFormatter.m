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

#if DEBUG
    // We already get date stamp in console, as it's printing via NSLog - BUT AFTER WE REMOVE IT, ADD IT BACK IN!
    return  [NSString stringWithFormat:@"[%@]: %@ (From: %@#L%lu)",
                                      level,
                                      logMessage -> _message,
                                      logMessage -> _fileName,
                                      (unsigned long)logMessage -> _line];
#else
    // Improve this to somewhat match above, after we finalize a good format - but add the datestamp back in
    return [NSString stringWithFormat:@"%@ %@#L%lu %@: %@",
                                      [self stringFromDate:logMessage->_timestamp],
                                      logMessage -> _function,
                                      (unsigned long)logMessage -> _line,
                                      level,
                                      logMessage -> _message];
#endif
}

@end
