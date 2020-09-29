@import CocoaLumberjack;

// Log level defaults to DEBUG in debug mode, and WARN in release.
#if DEBUG

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

#else

// Redefine NSLog to be a default CocoaLumberjack log.
#define NSLog(...) DDLogDebug(__VA_ARGS__)

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

#endif
