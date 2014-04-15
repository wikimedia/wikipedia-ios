//  Created by Monte Hurd on 4/14/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "ZeroStatusLabel.h"

@implementation ZeroStatusLabel

- (id)init
{
    self = [super init];
    if (self) {

        self.paddingEdgeInsets = UIEdgeInsetsZero;
    }
    return self;
}


// Label padding edge insets! From: http://stackoverflow.com/a/21934948

-(void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.paddingEdgeInsets)];
}

-(CGSize)intrinsicContentSize
{
    UIEdgeInsets insets = self.paddingEdgeInsets;
    self.preferredMaxLayoutWidth = self.bounds.size.width - (insets.left + insets.right);
    CGSize contentSize = [super intrinsicContentSize];
    contentSize.height += insets.top + insets.bottom;
    contentSize.width += insets.left + insets.right;
    return contentSize;
}

@end
