//  Created by Monte Hurd on 11/23/13.

#import "SearchBarLogoView.h"

@interface SearchBarLogoView()

@property (strong, nonatomic) UIImageView *logoImageView;

@end

@implementation SearchBarLogoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.logoImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.logoImageView.image = [UIImage imageNamed:@"w.png"];
        self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
        //self.logoImageView.backgroundColor = [UIColor redColor];
        [self addSubview:self.logoImageView];
    }
    return self;
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.logoImageView.frame = self.bounds;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat topPadding = (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) ? 0.0f : 2.0f;

    // Draw separator line between leftView and the text field itself.
    CGContextMoveToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect) + topPadding);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGContextSetStrokeColorWithColor(context, [[UIColor lightGrayColor] CGColor] );
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);
}

@end
