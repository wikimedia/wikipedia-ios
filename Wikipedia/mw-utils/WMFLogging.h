//
//  WMFLogging.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

// Log level defaults to DEBUG in debug mode, and WARN in release.
#if DEBUG
static const int ddLogLevel = DDLogLevelDebug;
#else
static const int ddLogLevel = DDLogLevelWarn;
#endif

// Redefine NSLog to be a default CocoaLumberjack log.
#define NSLog(...) DDLogDebug(__VA_ARGS__)
