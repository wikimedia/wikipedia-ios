@import Foundation;

extern NSString *_Nonnull const WMFApplicationGroupIdentifier;

@interface NSFileManager (WMFGroup)

- (nonnull NSURL *)wmf_containerURL;
- (nonnull NSString *)wmf_containerPath;

@end
