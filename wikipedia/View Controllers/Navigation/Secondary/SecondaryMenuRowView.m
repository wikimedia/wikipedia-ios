//  Created by Monte Hurd on 3/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SecondaryMenuRowView.h"
#import "PaddedLabel.h"
#import "Defines.h"
#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "NSObject+ConstraintsScale.h"

#define MENU_HEADING_FONT_SIZE (13.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_SUB_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.5f alpha:1.0f]
#define BORDER_COLOR [UIColor colorWithWhite:0.7f alpha:1.0f]

@interface SecondaryMenuRowView()

@property (nonatomic) BOOL showBottomBorder;
@property (nonatomic) BOOL showTopBorder;

// The top inset needs to be a constrained view rather than drawn
// so for RTL langs it gets "flipped" appropriately.
@property (nonatomic, strong) IBOutlet UIView *insetTopBorderView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *insetTopBorderHeightConstraint;

@end

@implementation SecondaryMenuRowView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.showBottomBorder = NO;
        self.showTopBorder = NO;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.insetTopBorderView.backgroundColor = BORDER_COLOR;
    
    BOOL isRTL = [WikipediaAppUtils isDeviceLanguageRTL];
    
    self.iconLabel.textAlignment = isRTL ? NSTextAlignmentLeft : NSTextAlignmentRight;
    
    self.textLabel.font = [UIFont systemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];
    self.iconLabel.font = [UIFont systemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];

    [self adjustConstraintsScaleForViews:@[self.iconLabel, self.optionSwitch]];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [BORDER_COLOR CGColor] );
    CGContextSetLineWidth(ctx, 1.0f / [UIScreen mainScreen].scale);
    if (self.showBottomBorder){
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    }
    if (self.showTopBorder){
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));
    }
    CGContextStrokePath(ctx);
}

-(void)setRowType:(RowType)rowType
{
    _rowType = rowType;
    switch (rowType) {
        case ROW_TYPE_HEADING:
            self.backgroundColor = CHROME_COLOR;
            self.textLabel.padding = UIEdgeInsetsMake(31, 0, 5, 0);
            self.textLabel.textColor = MENU_SUB_TITLE_TEXT_COLOR;
            self.textLabel.font = [UIFont systemFontOfSize:MENU_HEADING_FONT_SIZE];
            self.showBottomBorder = YES;
            self.showTopBorder = YES;
            if ([[SessionSingleton sharedInstance].site.language isEqualToString:@"en"]) {
                self.textLabel.text = [self.textLabel.text uppercaseString];
            }
            break;
        case ROW_TYPE_SELECTION:
            self.insetTopBorderHeightConstraint.constant = 0;
            self.textLabel.padding = UIEdgeInsetsMake(10, 0, 10, 0);
            self.backgroundColor = [UIColor whiteColor];
            
            break;
        default:
            break;
    }
    
    [self setNeedsDisplay];
}

-(void)setRowPosition:(RowPosition)rowPosition
{
    _rowPosition = rowPosition;
    switch (rowPosition) {
        case ROW_POSITION_TOP:
            self.showTopBorder = YES;
            self.showBottomBorder = NO;
            self.insetTopBorderHeightConstraint.constant = 0;
            break;
        case ROW_POSITION_UNKNOWN:
            self.showTopBorder = NO;
            self.showBottomBorder = NO;
            self.insetTopBorderHeightConstraint.constant = 1.0f / [UIScreen mainScreen].scale;
            break;
        default:
            break;
    }
    [self setNeedsDisplay];
    [self.insetTopBorderView setNeedsDisplay];
}

@end
