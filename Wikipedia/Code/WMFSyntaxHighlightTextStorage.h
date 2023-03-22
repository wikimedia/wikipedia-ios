#import <Foundation/Foundation.h>
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSyntaxHighlightTextStorage: NSTextStorage

@property (nonatomic, strong) UITraitCollection *fontSizeTraitCollection;
- (void)applyFontSizeTraitCollection:(UITraitCollection *)fontSizeTraitCollection;


@end

NS_ASSUME_NONNULL_END
