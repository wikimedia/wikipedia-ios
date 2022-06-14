#import <WMF/NSFileManager+WMFGroup.h>
#import "WMFQuoteMacros.h"

NSString *const WMFApplicationGroupIdentifier = @QUOTE(WMF_APP_GROUP_IDENTIFIER);

@implementation NSFileManager (WMFGroup)

- (nonnull NSURL *)wmf_containerURL {
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] isDirectory:YES];
}

- (nonnull NSString *)wmf_containerPath {
    return [[self wmf_containerURL] path];
}

@end
