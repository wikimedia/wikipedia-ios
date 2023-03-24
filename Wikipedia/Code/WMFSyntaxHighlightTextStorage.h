#import <Foundation/Foundation.h>
@import WMF.Swift;
@import UIKit;
@class NSMutableAttributedStringHelper;

NS_ASSUME_NONNULL_BEGIN

@interface WMFSyntaxHighlightTextStorage: NSTextStorage<WMFThemeable>

@property (nonatomic, strong) NSMutableAttributedStringHelper *mutableAttributedStringHelper;
@property (nonatomic, strong) UITraitCollection *fontSizeTraitCollection;
@property (strong, nonatomic, nonnull) WMFTheme *theme;
@property (assign, nonatomic) BOOL calculateSyntaxHighlightsUponEditEnabled;
- (void)applyTheme:(WMFTheme *)theme;

- (void)removeAttribute:(NSAttributedStringKey)name rangeValues:(NSArray<NSValue *> *)rangeValues;
- (void)addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs rangeValues:(NSArray<NSValue *> *)rangeValues;

- (void)updateFontSizeWithPreferredContentSize: (UIContentSizeCategory)preferredContentSizeCategory;

@end

NS_ASSUME_NONNULL_END
