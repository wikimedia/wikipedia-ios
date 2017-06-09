@import UIKit;

@interface UIImage (WMFImageProcessing)

/// @return The receiver's existing `CIImage` property, or a new `CIImage` initialized with the receiver.
- (CIImage *__nonnull)wmf_getOrCreateCIImage;

@end
