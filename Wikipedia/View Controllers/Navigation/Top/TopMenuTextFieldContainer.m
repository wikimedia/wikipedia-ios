//  Created by Monte Hurd on 6/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopMenuTextFieldContainer.h"
#import "TopMenuTextField.h"

@interface TopMenuTextFieldContainer ()

@property (nonatomic) UIEdgeInsets margin;

@end

@implementation TopMenuTextFieldContainer

- (instancetype)initWithMargin:(UIEdgeInsets)margin {
    self = [super init];
    if (self) {
        self.margin = margin;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.textField                                           = [[TopMenuTextField alloc] init];
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.textField];

    [self constrainTextField];
}

- (void)constrainTextField {
    NSDictionary* metrics = @{
        @"topMargin": @(self.margin.top),
        @"bottomMargin": @(self.margin.bottom),
        @"leftMargin": @(self.margin.left),
        @"rightMargin": @(self.margin.right)
    };

    NSDictionary* views = @{
        @"textField": self.textField
    };

    NSArray* viewConstraintArrays = @
    [
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(leftMargin)-[textField]-(rightMargin)-|"
                                                options:0
                                                metrics:metrics
                                                  views:views],

        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(topMargin)-[textField]-(bottomMargin)-|"
                                                options:0
                                                metrics:metrics
                                                  views:views],
    ];

    [self addConstraints:[viewConstraintArrays valueForKeyPath:@"@unionOfArrays.self"]];
}

/*
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   - (void)drawRect:(CGRect)rect
   {
    // Drawing code
   }
 */

@end
