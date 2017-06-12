@import Foundation;

@interface NSAttributedString (WMFModify)

/**
 *  Create copy of attributed string with attribute modification.
 *
 *  @param block invoked for each range attribute found. Return modified attribute object to be used for returned attributed string.
 *
 *  @return Copy of the attributed string with attribute adjustments.
 */

- (NSAttributedString *)wmf_attributedStringChangingAttribute:(NSString *)attribute
                                                    withBlock:(id (^)(id thisAttributeObject))block;

@end
