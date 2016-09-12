#import "NSFileManager+WMFGroup.h"

NSString *const WMFApplicationGroupIdentifier = @"group.org.wikimedia.wikipedia";

@implementation NSFileManager (WMFGroup)

- (nonnull NSURL *)wmf_containerURL {
    return [self containerURLForSecurityApplicationGroupIdentifier:WMFApplicationGroupIdentifier];
}

- (nonnull NSString *)wmf_containerPath {
    return [[self wmf_containerURL] path];
}

@end
