//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SearchResultCell.h"
#import "WikipediaAppUtils.h"
#import "NSObject+ConstraintsScale.h"
#import "PaddedLabel.h"

#define MINIMUM_VERTICAL_PADDING 8.0f

#define BOTTOM_BORDER_WIDTH (1.0f / [UIScreen mainScreen].scale)
#define BOTTOM_BORDER_COLOR [UIColor colorWithWhite:0.8 alpha:1.0]

@implementation SearchResultCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    self.resultLabel.padding =
        UIEdgeInsetsMake(MINIMUM_VERTICAL_PADDING, 0.0f, MINIMUM_VERTICAL_PADDING, 0.0f);

    // Initial changes to ui elements go here.
    // See: http://stackoverflow.com/a/15591474 for details.

    self.resultLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    
    [self adjustConstraintsScaleForViews:@[self.resultLabel, self.resultImageView]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    [self drawBottomBorder:rect];
}

-(void)drawBottomBorder:(CGRect)rect
{
    // Draw the border on the bottom of the cell from the label's left to right.
    // Done this way so when things get flipped around in RTL languages the
    // border moves too.

    // Right way to draw single pixel lines.
    // From: http://stackoverflow.com/a/22694298/135557
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, BOTTOM_BORDER_COLOR.CGColor);
    CGContextFillRect(ctx, CGRectMake(
                                          CGRectGetMinX(self.resultLabel.frame),
                                          CGRectGetMaxY(rect) - BOTTOM_BORDER_WIDTH,
                                          CGRectGetWidth(self.resultLabel.frame),
                                          BOTTOM_BORDER_WIDTH
                                          )
                      );
}

@end
