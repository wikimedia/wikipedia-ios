//
//  OAStackView+Hiding.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackView+Hiding.h"
#import <KVOController/FBKVOController.h>

@interface OAStackView ()
- (void)hideView:(UIView*)view;
- (void)unHideView:(UIView*)view;
@end

@implementation OAStackView (Hiding)

- (void)addObserverForView:(UIView*)view {
    [self.KVOController observe:view keyPath:@"hidden" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(OAStackView* observer, id object, NSDictionary *change) {
        
        BOOL isHidden = [change[NSKeyValueChangeNewKey] boolValue];
        BOOL wasHidden = [change[NSKeyValueChangeOldKey] boolValue];
        
        if (isHidden == wasHidden) {
            return;
        }
        
        if (isHidden) {
            [observer hideView:object];
        } else {
            [observer unHideView:object];
        }
    }];
}

- (void)removeObserverForView:(UIView*)view {
    [self.KVOController unobserve:view keyPath:@"hidden"];
}

- (void)addObserverForViews:(NSArray*)views {
  for (UIView *view in views) {
    [self addObserverForView:view];
  }
}

- (void)removeObserverForViews:(NSArray<__kindof UIView *> *)views {
  for (UIView *view in views) {
    [self removeObserverForView:view];
  }
}


@end
