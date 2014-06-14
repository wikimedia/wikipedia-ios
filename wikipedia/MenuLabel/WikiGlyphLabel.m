//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiGlyphLabel.h"

@implementation WikiGlyphLabel

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

-(void)setWikiText:(NSString *)text color:(UIColor *)color size:(CGFloat)size baselineOffset:(CGFloat)baselineOffset
{
    NSDictionary *attributes =
    @{
      NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Regular" size:size],
      NSForegroundColorAttributeName : color,
      NSBaselineOffsetAttributeName: @(baselineOffset)
      };
    
    self.attributedText =
        [[NSAttributedString alloc] initWithString: text
                                        attributes: attributes];
}

@end
