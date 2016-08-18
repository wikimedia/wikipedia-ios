#import "UIView+WMFSearchSubviews.h"
#import <BlocksKit/BlocksKit.h>

@implementation UIView (WMFSearchSubviews)

- (id)wmf_firstSubviewOfClass:(Class)aClass {
    // ideally we'd reuse -wmf_subviewsOfClass, but since the filtering isn't lazy, we have to
    // strictly find and return the first match
    return [self.subviews bk_match:^BOOL (UIView* subview) {
        return [subview isKindOfClass:aClass];
    }];
}

- (NSArray*)wmf_subviewsOfClass:(Class)aClass {
    return [self.subviews bk_select:^BOOL (UIView* subview) {
        return [subview isKindOfClass:aClass];
    }];
}

@end
