//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MenuLabel.h"

@implementation MenuLabel

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

-(void)setup
{
    self.textAlignment = NSTextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
    self.backgroundColor = [UIColor clearColor];
}

-(void)setWikiText:(NSString *)text color:(UIColor *)color size:(CGFloat)size
{
    NSDictionary *attributes =
    @{
      NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Regular" size:size],
      NSForegroundColorAttributeName : color,
      NSBaselineOffsetAttributeName: @2
      };
    
    self.attributedText =
        [[NSAttributedString alloc] initWithString: text
                                        attributes: attributes];
}

@end
