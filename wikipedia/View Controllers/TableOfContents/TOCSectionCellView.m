//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TOCSectionCellView.h"
#import "WMF_Colors.h"

@implementation TOCSectionCellView

- (id)init
{
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.clearsContextBeforeDrawing = NO;
        self.userInteractionEnabled = YES;
        self.numberOfLines = 0;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.backgroundColor = [UIColor clearColor];
        self.isHighlighted = NO;
        self.clipsToBounds = NO;
        self.opaque = YES;
    }
    return self;
}

-(void)setIsHighlighted:(BOOL)isHighlighted
{
    if (isHighlighted) {
        self.backgroundColor = [WMF_COLOR_BLUE colorWithAlphaComponent:0.6];
    }else{
        self.backgroundColor = [UIColor colorWithRed:0.049 green:0.049 blue:0.049 alpha:1.0];
    }
    
    if (isHighlighted) self.alpha = 1.0f;
    
    _isHighlighted = isHighlighted;

    self.textColor = isHighlighted ? [UIColor whiteColor] : [UIColor colorWithRed:0.573 green:0.58 blue:0.592 alpha:1];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
