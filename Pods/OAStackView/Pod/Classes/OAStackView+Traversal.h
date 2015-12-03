//
//  OAStackView+Traversal.h
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import <OAStackView/OAStackView.h>

@interface OAStackView (Traversal)

- (UIView*)visibleViewBeforeIndex:(NSInteger)index;
- (UIView*)visibleViewBeforeView:(UIView*)view;

- (UIView*)visibleViewAfterIndex:(NSInteger)index;
- (UIView*)visibleViewAfterView:(UIView*)view;

- (void)iterateVisibleViews:(void (^) (UIView *view, UIView *previousView))block;

- (NSArray*)currentVisibleViews;

- (UIView*)lastVisibleItem;

- (NSLayoutConstraint*)firstViewConstraint;
- (NSLayoutConstraint*)lastViewConstraint;

- (BOOL)isViewLastItem:(UIView*)view excludingItem:(UIView*)excludingItem;

@end
