//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuButtonView.h"
#import "TopMenuLabel.h"

@implementation TopMenuButtonView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.label = [[TopMenuLabel alloc] init];
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.label];
        [self constrainLabel];
    }
    return self;
}

-(void)setColor:(UIColor *)color
{
    [self.label setTextColor:color];
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
