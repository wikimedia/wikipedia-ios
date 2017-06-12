@import UIKit;

@interface NSParagraphStyle (WMFParagraphStyles)

/// Provides a backwards-compatible way to have "natural" text alignment of labels & buttons.
+ (NSParagraphStyle *)wmf_naturalAlignmentStyle;

+ (NSParagraphStyle *)wmf_tailTruncatingNaturalAlignmentStyle;

@end
