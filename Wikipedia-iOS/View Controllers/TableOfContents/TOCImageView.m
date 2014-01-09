//  Created by Monte Hurd on 1/9/14.

#import "TOCImageView.h"

@implementation TOCImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Effectively turn off the image view's intrinsic content size
// to make constraining it *without* the layout system taking
// into account the size of its UIImage easier.
-(CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
}

@end
