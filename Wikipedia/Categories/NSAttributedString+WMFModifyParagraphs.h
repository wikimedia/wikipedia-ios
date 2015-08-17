//  Created by Monte Hurd on 8/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface NSAttributedString (WMFModifyParagraphs)

/**
 *  Sometimes you need to adjust all paragraph styles without destroying existing paragraph style properties.
 *  (ie: you may want to adjust lineSpacing without affecting baseWritingDirection) This method invokes a
 *  callback block for each paragraph style attribute found. The callback lets you adjust each paragraph
 *  style, and the attributed string returned by the method will reflect the callback adjustments.
 *
 *  @param block Invoked for each paragraph style found. Passed a mutable copy of the paragraph style so tweaks are easy.
 *
 *  @return Copy of the attributed string with paragraph adjustments.
 */
- (NSAttributedString*)wmf_attributedStringWithParagraphStylesAdjustments:(void (^)(NSMutableParagraphStyle* existingParagraphStyle))block;

@end
