#import <Foundation/Foundation.h>
@import WMF.Swift;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSyntaxHighlightTextStorage: NSTextStorage<WMFThemeable>

@property (nonatomic, strong) UITraitCollection *fontSizeTraitCollection;
- (void)applyFontSizeTraitCollection:(UITraitCollection *)fontSizeTraitCollection;
@property (strong, nonatomic, nonnull) WMFTheme *theme;
- (void)applyTheme:(WMFTheme *)theme;


@end

NS_ASSUME_NONNULL_END
