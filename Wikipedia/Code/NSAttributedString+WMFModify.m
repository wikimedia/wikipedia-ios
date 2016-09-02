#import "NSAttributedString+WMFModify.h"

@implementation NSAttributedString (WMFModify)

- (NSAttributedString *)wmf_attributedStringChangingAttribute:(NSString *)attribute
                                                    withBlock:(id (^)(id thisAttributeObject))block {
    if (!block || self.length == 0) {
        return self;
    }

    NSMutableAttributedString *mutableCopy = self.mutableCopy;

    [mutableCopy beginEditing];

    [self enumerateAttribute:attribute
                     inRange:NSMakeRange(0, self.length)
                     options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                  usingBlock:^(id value, NSRange range, BOOL *stop) {
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

@end
