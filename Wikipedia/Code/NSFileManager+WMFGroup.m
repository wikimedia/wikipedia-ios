#import "NSFileManager+WMFGroup.h"

#if ALPHA
NSString *const WMFApplicationGroupIdentifier = @"group.org.wikimedia.wikipedia.alpha";
#elif BETA
NSString *const WMFApplicationGroupIdentifier = @"group.org.wikimedia.wikipedia.beta";
#else
NSString *const WMFApplicationGroupIdentifier = @"group.org.wikimedia.wikipedia";
#endif

@implementation NSFileManager (WMFGroup)

- (nonnull NSURL *)wmf_containerURL {
    return [self containerURLForSecurityApplicationGroupIdentifier:WMFApplicationGroupIdentifier];
}

- (nonnull NSString *)wmf_containerPath {
    return [[self wmf_containerURL] path];
}

@end
