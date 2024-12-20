@import CocoaLumberjack;

#if DEBUG

// Change to DDLogLevelAll to enable all logging
static const DDLogLevel ddLogLevel = DDLogLevelWarning;

#else

// Redefine NSLog to be a default CocoaLumberjack log.
#define NSLog(...) DDLogDebug(__VA_ARGS__)

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

#endif
