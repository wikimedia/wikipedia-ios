//  Created by Monte Hurd on 9/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIView+ConstraintsScale.h"

@implementation UIView (ConstraintsScale)

- (void)adjustConstraintsFor:(NSLayoutAttribute)firstAttribute byMultiplier:(CGFloat)multiplier {
    // Scale any constraints touching this view. (from superview constraints)
    for (NSLayoutConstraint* c in self.superview.constraints.copy) {
        if (c.firstAttribute == firstAttribute) {
            if ((c.firstItem == self) || (c.secondItem == self)) {
                c.constant = (NSInteger)(c.constant * multiplier);
            }
        }
    }

    // Scale any constraints touching this view. (from view constraints)
    for (NSLayoutConstraint* c in self.constraints.copy) {
        if (
            (c.firstItem == self)
            &&
            (c.firstAttribute == firstAttribute)
            &&
            (c.secondAttribute == NSLayoutAttributeNotAnAttribute)
            ) {
            c.constant = (NSInteger)(c.constant * multiplier);
        }
    }

    /*
       // Reminder: don't adjust the padding... it messes up when you, say, repeatedly
       // tap search/cancel because it becomes additive.

       PaddedLabel *paddedLabel = nil;
       if([self isKindOfClass:[WikiGlyphButton class]]){
        WikiGlyphButton *b = (WikiGlyphButton *)self;
        paddedLabel = b.label;
       }else if([self isKindOfClass:[PaddedLabel class]]){
        paddedLabel = (PaddedLabel *)self;
       }

       if (paddedLabel) {
        paddedLabel.padding = UIEdgeInsetsMake(
            (NSInteger)(paddedLabel.padding.top * multiplier),
            (NSInteger)(paddedLabel.padding.left * multiplier),
            (NSInteger)(paddedLabel.padding.bottom * multiplier),
            (NSInteger)(paddedLabel.padding.right * multiplier)
        );
       }
     */
}

@end
