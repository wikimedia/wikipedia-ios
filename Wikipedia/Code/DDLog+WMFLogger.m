//
//  DDLog+WMFLogger.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "DDLog+WMFLogger.h"
#import "WMFLogFormatter.h"
#import "Wikipedia-Swift.h"

@implementation DDLog (WMFLogger)

+ (void)load {
    [self wmf_addLoggersForCurrentConfiguration];
    [self wmf_setSwiftDefaultLogLevel:LOG_LEVEL_DEF];
}

+ (void)wmf_addLoggersForCurrentConfiguration {
    // only add TTY in debug mode
#if DEBUG
    [self wmf_addWMFFormattedLogger:[DDTTYLogger sharedInstance]];
#endif
    // always add ASLLogger
    [self wmf_addWMFFormattedLogger:[DDASLLogger sharedInstance]];
}

+ (void)wmf_addWMFFormattedLogger:(id<DDLogger>)logger {
    [logger setLogFormatter:[WMFLogFormatter new]];
    [DDLog addLogger:logger];
}

@end
