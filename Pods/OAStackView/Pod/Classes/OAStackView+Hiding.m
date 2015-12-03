//
//  OAStackView+Hiding.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackView+Hiding.h"

@interface OAStackView ()
- (void)hideView:(UIView*)view;
- (void)unHideView:(UIView*)view;
@end

@implementation OAStackView (Hiding)

- (void)addObserverForView:(UIView*)view {
  [view addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)removeObserverForView:(UIView*)view {
  [view removeObserver:self forKeyPath:@"hidden"];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  BOOL isHidden = [change[NSKeyValueChangeNewKey] boolValue];
  BOOL wasHidden = [change[NSKeyValueChangeOldKey] boolValue];
  
  if (isHidden == wasHidden) {
    return;
  }
  
  if (isHidden) {
    [self hideView:object];
  } else {
    [self unHideView:object];
  }
  
}

#pragma mark subviews

- (void)didAddSubview:(UIView *)subview {
  [super didAddSubview:subview];
  [self addObserverForView:subview];
}

- (void)willRemoveSubview:(UIView *)subview {
  [super willRemoveSubview:subview];
  [self removeObserverForView:subview];
}

@end
