//  Created by Monte Hurd on 4/24/14.

#import "EditSummaryHandleView.h"

struct LINE
{
    CGPoint pointA;
    CGPoint pointB;
};

@implementation EditSummaryHandleView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.state = EDIT_SUMMARY_HANDLE_BOTTOM;
    }
    return self;
}

-(void)setState:(EditSummaryHandleState)state
{
    _state = state;
    [self setNeedsDisplay];
}

// Convert unit space point to rect space point.
-(CGPoint)rectPointFromUnitPoint:(CGPoint)unitPoint
{
    return (CGPoint){
        unitPoint.x * self.bounds.size.width,
        unitPoint.y * self.bounds.size.height
    };
}

-(void)addLine:(struct LINE)line toPath:(UIBezierPath *)path
{
    [path moveToPoint:[self rectPointFromUnitPoint:line.pointA]];
    [path addLineToPoint:[self rectPointFromUnitPoint:line.pointB]];
}

- (void)drawRect:(CGRect)rect
{
    // Draw either a "=" shape or a "v" shape depending on state.
    // Scales with this view's scale.

    CGFloat h = 0.12; // Half height (vertical deviation from vertical center)
    CGFloat p = 0.10; // Padding on line sides

    struct LINE lineOne, lineTwo;
    
    switch (self.state) {
        case EDIT_SUMMARY_HANDLE_TOP:{
            // A slight "v" shape. Coords in unit space.
            lineOne = (struct LINE){{p, 0.5-h}, {0.5, 0.5+h}};
            lineTwo = (struct LINE){{0.5, 0.5+h}, {1.0-p, 0.5-h}};
        }
            break;
        case EDIT_SUMMARY_HANDLE_BOTTOM:{
            // Two lines resembling an equals "=" sign. Coords in unit space.
            lineOne = (struct LINE){{p, 0.5-h}, {1.0-p, 0.5-h}};
            lineTwo = (struct LINE){{p, 0.5+h}, {1.0-p, 0.5+h}};
        }
            break;
    }

    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [self addLine:lineOne toPath:path];
    [self addLine:lineTwo toPath:path];

    [path setLineWidth:2.0];
    [path setLineCapStyle:kCGLineCapRound];
    [path setLineJoinStyle:kCGLineJoinRound];

    [[UIColor colorWithRed:0.72 green:0.72 blue:0.72 alpha:1.0] set];
    
    [path stroke];
}

@end
