//  Created by Monte Hurd on 12/28/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TOCSectionCellView.h"
#import "WMF_Colors.h"
#import "UIView+ConstraintsScale.h"
#import "Defines.h"

#define SELECTION_INDICATOR_WIDTH (6.0 * MENUS_SCALE_MULTIPLIER)
#define SELECTION_INDICATOR_VERTICAL_INSET (10.0 * MENUS_SCALE_MULTIPLIER)

@interface TOCSectionCellView ()

@property (nonatomic) NSInteger level;
@property (nonatomic) BOOL isLead;
@property (nonatomic) BOOL isRTL;

@end

@implementation TOCSectionCellView

- (id)initWithLevel:(NSInteger)level isLead:(BOOL)isLead isRTL:(BOOL)isRTL {
    self = [super init];

    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.clearsContextBeforeDrawing                = NO;
        self.userInteractionEnabled                    = YES;
        self.numberOfLines                             = 0;
        self.lineBreakMode                             = NSLineBreakByWordWrapping;
        self.backgroundColor                           = [UIColor clearColor];
        self.isSelected                                = NO;
        self.isHighlighted                             = NO;
        self.clipsToBounds                             = NO;
        self.opaque                                    = YES;
        self.level                                     = level;
        self.isLead                                    = isLead;
        self.isRTL                                     = isRTL;

        self.font = (self.level == 1) ? [UIFont boldSystemFontOfSize : 17.0 * MENUS_SCALE_MULTIPLIER] :[UIFont systemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];

        if (self.isLead) {
            self.backgroundColor = WMF_COLOR_BLUE;
        }

        self.textColor = (self.level <= 1) ?
                         [UIColor whiteColor]
                         :
                         [UIColor colorWithRed:0.573 green:0.58 blue:0.592 alpha:1];
    }

    return self;
}

- (void)setIsHighlighted:(BOOL)isHighlighted {
    _isHighlighted = isHighlighted;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (!self.isSelected) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat width = SELECTION_INDICATOR_WIDTH;

    BOOL devoMode = NO;

    if (!devoMode) {
        CGContextSetFillColorWithColor(context, WMF_COLOR_BLUE.CGColor);

        CGFloat originX = (!self.isRTL) ? rect.origin.x : rect.size.width - width;

        CGRect rectangle = CGRectMake(
            originX,
            rect.origin.y + SELECTION_INDICATOR_VERTICAL_INSET,
            width,
            rect.size.height - (SELECTION_INDICATOR_VERTICAL_INSET * 2.0)
            );
        CGContextFillRect(context, rectangle);
    } else {
        NSInteger i = (NSInteger)self.level;
        for (NSInteger j = 0; j < i; j++) {
            CGFloat vInset = ((j + 1) * SELECTION_INDICATOR_VERTICAL_INSET);

            CGFloat originX = (!self.isRTL) ? (rect.origin.x + (width * j)) : ((rect.size.width - width) - (width * j));

            CGRect rectangle = CGRectMake(originX, rect.origin.y + vInset, width, rect.size.height - (vInset * 2.0));
            CGFloat alpha    = (1.0 * (1.0 / (j + 1)));

            CGContextSetFillColorWithColor(context, [WMF_COLOR_BLUE colorWithAlphaComponent:alpha].CGColor);
            //CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor );

            CGContextFillRect(context, rectangle);
            //CGContextStrokeRect(context, rectangle);
        }
        //width *= self.level;
    }
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING toc section cell!");
   }
 */

@end
