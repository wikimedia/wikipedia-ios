#import <Foundation/Foundation.h>
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableAttributedString (WikitextEditingExtensions)

-(void)addWikitextSyntaxFormattingWithSearchRange: (NSRange)searchRange fontSizeTraitCollection: (UITraitCollection *)fontSizeTraitCollection needsColors: (BOOL)needsColors;

@end

NS_ASSUME_NONNULL_END
