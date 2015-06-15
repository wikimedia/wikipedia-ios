//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, WMFButtonType) {
    WMF_BUTTON_W,
    WMF_BUTTON_SHARE,
    WMF_BUTTON_FORWARD,
    WMF_BUTTON_BACKWARD,
    WMF_BUTTON_HEART,
    WMF_BUTTON_TOC,
    WMF_BUTTON_X,
    WMF_BUTTON_X_WHITE,
    WMF_BUTTON_TRASH,
    WMF_BUTTON_TRANSLATE,
    WMF_BUTTON_MAGNIFY,
    WMF_BUTTON_RELOAD,
    WMF_BUTTON_CARET_LEFT
};

@interface UIButton (WMFGlyph)

+ (UIButton*)wmf_buttonType:(WMFButtonType)type
                    handler:(void (^)(id sender))action;

@end