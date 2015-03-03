//  Created by Monte Hurd on 4/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class MenuLabel;

@interface MenuButton : UIView

- (instancetype)initWithText:(NSString*)text
                    fontSize:(CGFloat)size
                        bold:(BOOL)bold
                       color:(UIColor*)color
                     padding:(UIEdgeInsets)padding
                      margin:(UIEdgeInsets)margin;

/*
   If enabled, color is used for background and border color - with white text.
   If not enabled, color is used for border and text color - with transparent background.
 */

@property (nonatomic) BOOL enabled;

@property (strong, nonatomic, readonly) NSString* text;

@property (strong, nonatomic) UIColor* color;

@end
