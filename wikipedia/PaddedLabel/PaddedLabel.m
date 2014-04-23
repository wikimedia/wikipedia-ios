//  Created by Monte Hurd on 4/17/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PaddedLabel.h"

@implementation PaddedLabel

-(void)setup
{
    self.padding = UIEdgeInsetsZero;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(CGFloat)getPaddedMaxLayoutWidth
{
    return self.bounds.size.width - (self.padding.left + self.padding.right);
}

-(void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    // Keep preferredMaxLayoutWidth in sync with new width so label will grow
    // vertically to encompass its text if the label's width constraint changes.
    // (taking padding into account)
    self.preferredMaxLayoutWidth = [self getPaddedMaxLayoutWidth];
}

// Label padding edge insets! From: http://stackoverflow.com/a/21934948

-(void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.padding)];
}

-(CGSize)intrinsicContentSize
{
    // Set preferredMaxLayoutWidth before the call to super so the super call can
    // take into account the padding. Needed because the padding can affect how many
    // lines are being displayed, which can increase the intrinsicContentSize
    // height.
    self.preferredMaxLayoutWidth = [self getPaddedMaxLayoutWidth];
    
    CGSize contentSize = [super intrinsicContentSize];
    contentSize.height += self.padding.top + self.padding.bottom;
    contentSize.width += self.padding.left + self.padding.right;
    return contentSize;
}

@end
