//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MenuButton.h"
#import "MenuLabel.h"
#import "UIView+RemoveConstraints.h"
#import "Defines.h"

@interface MenuButton ()

@property (strong, nonatomic) NSString* text;

@property (strong, nonatomic) MenuLabel* label;

@property (strong, nonatomic) UIColor* oldColor;

@property (nonatomic) CGFloat fontSize;

@property (nonatomic) BOOL fontBold;

@property (nonatomic) UIEdgeInsets padding;

@property (nonatomic) UIEdgeInsets margin;

@end

@implementation MenuButton

- (instancetype)initWithCoder:(NSCoder*)coder {
    return [self initWithText:@"" fontSize:16.0 * MENUS_SCALE_MULTIPLIER bold:NO color:[UIColor blackColor] padding:UIEdgeInsetsZero margin:UIEdgeInsetsZero];
}

- (instancetype)init {
    return [self initWithText:@"" fontSize:16.0 * MENUS_SCALE_MULTIPLIER bold:NO color:[UIColor blackColor] padding:UIEdgeInsetsZero margin:UIEdgeInsetsZero];
}

- (instancetype)initWithText:(NSString*)text
                    fontSize:(CGFloat)size
                        bold:(BOOL)bold
                       color:(UIColor*)color
                     padding:(UIEdgeInsets)padding
                      margin:(UIEdgeInsets)margin {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.fontSize                                  = size * MENUS_SCALE_MULTIPLIER;
        self.padding                                   = padding;
        self.text                                      = text;
        self.enabled                                   = NO;
        self.clipsToBounds                             = YES;
        self.fontBold                                  = bold;
        self.label                                     = [[MenuLabel alloc] initWithText:text fontSize:size bold:bold color:color padding:padding];
        self.color                                     = color;
        self.oldColor                                  = color;
        [self addSubview:self.label];
        self.margin = margin;
        [self constrainLabel];
        self.isAccessibilityElement = YES;
        self.accessibilityTraits    = UIAccessibilityTraitButton;
    }
    return self;
}

- (void)setColor:(UIColor*)color {
    _color = color;

    if (self.enabled) {
        self.label.backgroundColor   = color;
        self.label.layer.borderColor = color.CGColor;
        self.label.color             = [UIColor whiteColor];
    } else {
        self.label.backgroundColor   = [UIColor clearColor];
        self.label.layer.borderColor = color.CGColor;
        self.label.color             = color;
    }
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;

    // Force the color to changes to proper scheme for this enabled state.
    [self setColor:self.color];
}

- (void)constrainLabel {
    [self.label removeConstraintsOfViewFromView:self];

    NSDictionary* metrics = @{
        @"marginTop": @(self.margin.top * MENUS_SCALE_MULTIPLIER),
        @"marginLeft": @(self.margin.left * MENUS_SCALE_MULTIPLIER),
        @"marginBottom": @(self.margin.bottom * MENUS_SCALE_MULTIPLIER),
        @"marginRight": @(self.margin.right * MENUS_SCALE_MULTIPLIER)
    };

    NSDictionary* views = @{
        @"label": self.label
    };

    NSArray* constraintArrays = @
    [

        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(marginLeft)-[label]-(marginRight)-|"
                                                options:0
                                                metrics:metrics
                                                  views:views],

        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(marginTop)-[label]-(marginBottom)-|"
                                                options:0
                                                metrics:metrics
                                                  views:views]

    ];

    [self addConstraints:[constraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

@end
