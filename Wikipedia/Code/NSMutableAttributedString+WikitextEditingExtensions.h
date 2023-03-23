#import <Foundation/Foundation.h>
@import UIKit;
@import WMF.Swift;

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableAttributedString (WikitextEditingExtensions)

-(void)addWikitextSyntaxFormattingWithSearchRange: (NSRange)searchRange fontSizeTraitCollection: (UITraitCollection *)fontSizeTraitCollection needsColors: (BOOL)needsColors theme: (WMFTheme *)theme;

@end

NS_ASSUME_NONNULL_END
