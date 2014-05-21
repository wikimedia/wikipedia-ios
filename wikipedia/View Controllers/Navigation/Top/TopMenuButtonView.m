//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuButtonView.h"
#import "TopMenuLabel.h"

@implementation TopMenuButtonView

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
    self.enabled = YES;
    self.clipsToBounds = YES;
    self.label = [[TopMenuLabel alloc] init];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.label];
    [self constrainLabel];
}

-(void)setColor:(UIColor *)color
{
    [self.label setTextColor:color];
}

-(void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.alpha = (enabled) ? 1.0 : 0.5;
}

-(void)constrainLabel
{
    NSDictionary *metrics = @{
    };
    
    NSDictionary *views = @{
        @"label": self.label
    };

    NSArray *constraintArrays = @
        [

         [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[label]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views],

         [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[label]|"
                                                 options: 0
                                                 metrics: metrics
                                                   views: views]

     ];

    [self addConstraints:[constraintArrays valueForKeyPath:@"@unionOfArrays.self"]];

}

@end
