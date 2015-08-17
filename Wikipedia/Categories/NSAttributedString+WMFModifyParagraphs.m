//  Created by Monte Hurd on 8/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSAttributedString+WMFModifyParagraphs.h"

@implementation NSAttributedString (WMFModifyParagraphs)

- (NSAttributedString*)wmf_attributedStringWithParagraphStylesAdjustments:(void (^)(NSMutableParagraphStyle* existingParagraphStyle))block {
    if (!block) {
        return self;
    } else {
        NSMutableAttributedString* mutableCopy = self.mutableCopy;
        [self enumerateAttribute:NSParagraphStyleAttributeName
                         inRange:NSMakeRange(0, self.length)
                         options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                      usingBlock:^(NSParagraphStyle* pStyle, NSRange range, BOOL* stop){
            NSMutableParagraphStyle* mutablePStyle = pStyle.mutableCopy;
            block(mutablePStyle);
            [mutableCopy addAttribute:NSParagraphStyleAttributeName value:mutablePStyle range:range];
        }];
        return mutableCopy;
    }
}

@end
