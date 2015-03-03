//  Created by Monte Hurd on 6/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

/*
   This container object is used to present a TopMenuTextField with margin.
   This was done so the top menu can set the height of all its subviews (buttons,
   text fields etc) consistently. So this container would be constrained by the
   top menu to, say, 50px height, just like every other top menu subview, but
   this container can add margin around its own text field subview independently.
 */

@class TopMenuTextField;

@interface TopMenuTextFieldContainer : UIView

@property(nonatomic, retain) TopMenuTextField* textField;

- (instancetype)initWithMargin:(UIEdgeInsets)margin;

@end
