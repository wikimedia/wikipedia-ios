//  Created by Monte Hurd on 8/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSAttributedString+WMFModify.h"

@implementation NSAttributedString (WMFModify)

- (NSAttributedString*)wmf_attributedStringChangingAttribute:(NSString*)attribute
                                                   withBlock:(id (^)(id thisAttributeObject))block {
    if (!block || self.length == 0) {
        return self;
    }

    NSMutableAttributedString* mutableCopy = self.mutableCopy;

    [mutableCopy beginEditing];

    [self enumerateAttribute:attribute
                     inRange:NSMakeRange(0, self.length)
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL* stop){
        id newValue = block(value);
        if (newValue) {
            [mutableCopy addAttribute:attribute value:newValue range:range];
        } else {
            [mutableCopy removeAttribute:attribute range:range];
        }
    }];

    [mutableCopy endEditing];

    return mutableCopy;
}

- (NSAttributedString*)wmf_rightTrim {
    if (self.length == 0) {
        return self;
    }
    static NSCharacterSet* invertedWhitespaceCharSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        invertedWhitespaceCharSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    });

    NSRange lastNonWhiteSpaceRange = [self.string rangeOfCharacterFromSet:invertedWhitespaceCharSet options:NSBackwardsSearch];

    if (lastNonWhiteSpaceRange.location != NSNotFound) {
        return [self attributedSubstringFromRange:NSMakeRange(0, lastNonWhiteSpaceRange.location + 1)];
    }
    return self;
}

@end
