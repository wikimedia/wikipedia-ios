//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIBarButtonItem+WMFButtonConvenience.h"

@implementation UIBarButtonItem (WMFButtonConvenience)

+ (UIBarButtonItem*)wmf_buttonType:(WMFButtonType)type
                           handler:(void (^ __nullable)(id sender))action {
    return [[UIBarButtonItem alloc] initWithCustomView:[UIButton wmf_buttonType:type handler:action]];
}

- (UIButton*)wmf_UIButton {
    return [self.customView isKindOfClass:[UIButton class]] ? (UIButton*)self.customView : nil;
}

@end
