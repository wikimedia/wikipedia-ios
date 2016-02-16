//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, WMFButtonType) {
    WMFButtonTypeX,
    WMFButtonTypeCaretLeft
};

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (WMFButton)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type handler:(void (^ __nullable)(id sender))action;

- (void)wmf_setButtonType:(WMFButtonType)type;

@end

NS_ASSUME_NONNULL_END
