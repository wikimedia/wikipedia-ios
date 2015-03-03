//  Created by Monte Hurd on 12/9/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "PaddedLabel.h"

typedef NS_ENUM (NSInteger, AlertType) {
    ALERT_TYPE_UNKNOWN,
    ALERT_TYPE_TOP,
    ALERT_TYPE_BOTTOM,
    ALERT_TYPE_FULLSCREEN
};

@interface AlertLabel : PaddedLabel

- (id)initWithText:(id)text duration:(CGFloat)duration padding:(UIEdgeInsets)padding type:(AlertType)type;

- (void)hide;

- (void)fade;

@end
