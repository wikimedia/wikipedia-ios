//  Created by Monte Hurd on 11/23/13.

#import "SearchBarLogoView.h"
#import "UIView+RemoveConstraints.h"

@interface SearchBarLogoView()

@property (strong, nonatomic) UIImageView *logoImageView;

@end

@implementation SearchBarLogoView

- (id)init
{
    self = [super init];
    if (self) {
        self.logoImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.logoImageView.image = [UIImage imageNamed:@"w.png"];
        self.logoImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.logoImageView];
    }
    return self;
}

-(void)updateConstraints
{
    [super updateConstraints];
    [self constrainLogoImageView];
}

-(void)constrainLogoImageView
{
    // Remove any existing logoImageView constraints.
    [self.logoImageView removeConstraintsOfViewFromView:self];
    
    NSArray *constraints = @[
                             
                             [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[logoImageView]|"
                                                                     options: 0
                                                                     metrics: nil
                                                                       views: @{@"logoImageView": self.logoImageView}
                              ],
                             
                             [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[logoImageView]|"
                                                                     options: 0
                                                                     metrics: nil
                                                                       views: @{@"logoImageView": self.logoImageView}
                              ]
                             
                             ];
    
    [self addConstraints:[constraints valueForKeyPath:@"@unionOfArrays.self"]];
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
