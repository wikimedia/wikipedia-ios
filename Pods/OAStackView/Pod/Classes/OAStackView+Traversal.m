//
//  OAStackView+Traversal.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackView+Traversal.h"

@implementation OAStackView (Traversal)

- (UIView*)visibleViewBeforeView:(UIView*)view {
  NSInteger index = [self.subviews indexOfObject:view];
  if (index == NSNotFound) { return nil; }
  
  return [self visibleViewBeforeIndex:index];
}

- (UIView*)visibleViewAfterView:(UIView*)view {
  NSInteger index = [self.subviews indexOfObject:view];
  if (index == NSNotFound) { return nil; }
  
  return [self visibleViewAfterIndex:index];
}

- (UIView*)visibleViewAfterIndex:(NSInteger)index {
  for (NSInteger i = index + 1; i < self.subviews.count; i++) {
    UIView *theView = self.subviews[i];
    if (!theView.hidden) {
      return theView;
    }
  }
  
  return nil;
}

- (UIView*)visibleViewBeforeIndex:(NSInteger)index {
  for (NSInteger i = index - 1; i >= 0; i--) {
    UIView *theView = self.subviews[i];
    if (!theView.hidden) {
      return theView;
    }
  }
  
  return nil;
}

- (UIView*)lastVisibleItem {
  return [self visibleViewBeforeIndex:self.subviews.count];
}

- (void)iterateVisibleViews:(void (^) (UIView *view, UIView *previousView))block {
  
  id previousView;
  for (UIView *view in self.subviews) {
    if (view.isHidden) { continue; }
    
    block(view, previousView);
    previousView = view;
  }
}

- (NSArray*)currentVisibleViews {
  NSMutableArray *arr = [@[] mutableCopy];
  [self iterateVisibleViews:^(UIView *view, UIView *previousView) {
    [arr addObject:view];
  }];
  return arr;
}

- (BOOL)isLastVisibleItem:(UIView*)view {
  return view == [self lastVisibleItem];
}

- (NSLayoutConstraint*)lastViewConstraint {
  for (NSLayoutConstraint *constraint in self.constraints) {
    
    if (self.axis == UILayoutConstraintAxisVertical) {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeBottom) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeBottom)) {
        return constraint;
      }
    } else {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeTrailing) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeTrailing)) {
        return constraint;
      }
    }
    
  }
  return nil;
}


- (NSLayoutConstraint*)firstViewConstraint {
  for (NSLayoutConstraint *constraint in self.constraints) {
    
    if (self.axis == UILayoutConstraintAxisVertical) {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeTop) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeTop)) {
        return constraint;
      }
    } else {
      if ( (constraint.firstItem == self && constraint.firstAttribute == NSLayoutAttributeLeading) ||
          (constraint.secondItem == self && constraint.secondAttribute == NSLayoutAttributeLeading)) {
        return constraint;
      }
    }
    
  }
  return nil;
}

- (BOOL)isViewLastItem:(UIView*)view excludingItem:(UIView*)excludingItem {
  NSArray<__kindof UIView *> *visible = [self currentVisibleViews];
  NSInteger index = [visible indexOfObject:view];
  NSInteger exclutedIndex = [visible indexOfObject:excludingItem];
  
  
  return index == visible.count - 1 ||
  (exclutedIndex  == visible.count - 1 && index  == visible.count - 2);
}


@end
