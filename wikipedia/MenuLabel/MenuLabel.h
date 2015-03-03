//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PaddedLabel.h"

@interface MenuLabel : PaddedLabel

- (instancetype)initWithText:(NSString*)text
                    fontSize:(CGFloat)size
                        bold:(BOOL)bold
                       color:(UIColor*)color
                     padding:(UIEdgeInsets)padding;

@property (strong, nonatomic) UIColor* color;

@end
