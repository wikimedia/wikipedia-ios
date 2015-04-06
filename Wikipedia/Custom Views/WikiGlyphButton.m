//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WikiGlyphButton.h"
#import "WikiGlyphLabel.h"

@implementation WikiGlyphButton

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.enabled                                         = YES;
    self.clipsToBounds                                   = YES;
    self.label                                           = [[WikiGlyphLabel alloc] init];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.isAccessibilityElement                          = YES;
    self.accessibilityTraits                             = UIAccessibilityTraitButton;
    [self addSubview:self.label];
    [self constrainLabel];
}

- (void)setColor:(UIColor*)color {
    _color = color;
    [self.label setTextColor:color];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled   = enabled;
    self.alpha = (enabled) ? 1.0 : 0.2;
    if (enabled) {
        self.accessibilityTraits = self.accessibilityTraits & (~UIAccessibilityTraitNotEnabled);
    } else {
        self.accessibilityTraits = self.accessibilityTraits | UIAccessibilityTraitNotEnabled;
    }
}

- (void)constrainLabel {
    NSDictionary* metrics = @{
    };

    NSDictionary* views = @{
        @"label": self.label
    };

    NSArray* constraintArrays = @
    [

        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|"
                                                options:0
                                                metrics:metrics
                                                  views:views],

        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|"
                                                options:0
                                                metrics:metrics
                                                  views:views]

    ];

    [self addConstraints:[constraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

@end
