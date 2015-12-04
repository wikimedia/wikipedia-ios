//
//  OAStackView.m
//  OAStackView
//
//  Created by Omar Abdelhafith on 14/06/2015.
//  Copyright © 2015 Omar Abdelhafith. All rights reserved.
//

#import "OAStackView.h"
#import "OAStackView+Constraint.h"
#import "OAStackView+Hiding.h"
#import "OAStackView+Traversal.h"
#import "OAStackViewAlignmentStrategy.h"
#import "OAStackViewDistributionStrategy.h"
#import "OATransformLayer.h"
#import <objc/runtime.h>

@interface OAStackView ()
@property(nonatomic, strong) NSMutableArray *mutableArrangedSubviews;
@property(nonatomic) OAStackViewAlignmentStrategy *alignmentStrategy;
@property(nonatomic) OAStackViewDistributionStrategy *distributionStrategy;

// Not implemented but needed for backward compatibility with UIStackView
@property(nonatomic,getter=isBaselineRelativeArrangement) BOOL baselineRelativeArrangement;
@end

@implementation OAStackView

+ (Class)layerClass {
    return [OATransformLayer class];
}

#pragma mark - Initialization

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super initWithCoder:decoder];
  
  if (self) {
      
      [self commonInitWithInitalSubviews:@[]];
      
      // Not sure why, but [self isKindOfClass:@"UIStackView"] didn't work here
      if ([NSStringFromClass([self class]) isEqualToString:@"UIStackView"]) {
//          NSArray* arranedViews = [decoder decodeObjectForKey:@"UIStackViewArrangedSubviews"];
          _axis = [decoder decodeIntegerForKey:@"UIStackViewAxis"];
          _spacing = [decoder decodeDoubleForKey:@"UIStackViewSpacing"];
          _distribution = [decoder decodeIntegerForKey:@"UIStackViewDistribution"];
          _alignment = [decoder decodeIntegerForKey:@"UIStackViewAlignment"];
          _baselineRelativeArrangement = [decoder decodeBoolForKey:@"UIStackViewBaselineRelative"];
          _layoutMarginsRelativeArrangement = [decoder decodeBoolForKey:@"UIStackViewLayoutMarginsRelative"];
          _alignmentStrategy = [OAStackViewAlignmentStrategy strategyWithStackView:self];
          _distributionStrategy = [OAStackViewDistributionStrategy strategyWithStackView:self];
      }
      [self layoutArrangedViews];
  }
  return self;
}

- (instancetype)initWithArrangedSubviews:(NSArray<__kindof UIView *> *)views {
  self = [super initWithFrame:CGRectZero];
  
  if (self) {
    [self commonInitWithInitalSubviews:views];
    [self layoutArrangedViews];
  }
  
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithArrangedSubviews:@[]];
}

- (void)commonInitWithInitalSubviews:(NSArray *)initialSubviews {
  _mutableArrangedSubviews = [initialSubviews mutableCopy];
  [self addViewsAsSubviews:initialSubviews];

  _axis = UILayoutConstraintAxisVertical;
  _alignment = OAStackViewAlignmentFill;
  _distribution = OAStackViewDistributionFill;

  _layoutMargins = UIEdgeInsetsMake(0, 8, 0, 8);
  _layoutMarginsRelativeArrangement = NO;

  _alignmentStrategy = [OAStackViewAlignmentStrategy strategyWithStackView:self];
  _distributionStrategy = [OAStackViewDistributionStrategy strategyWithStackView:self];
}

#pragma mark - Properties

- (NSArray *)arrangedSubviews {
  return self.mutableArrangedSubviews.copy;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    // Does not have any effect because `CATransformLayer` is not rendered.
}

- (void)setOpaque:(BOOL)opaque {
  // Does not have any effect because `CATransformLayer` is not rendered.
}

- (void)setClipsToBounds:(BOOL)clipsToBounds {
  // Does not have any effect because `CATransformLayer` is not rendered.
}

- (void)setSpacing:(CGFloat)spacing {
  if (_spacing == spacing) { return; }
  
  _spacing = spacing;
  
  for (NSLayoutConstraint *constraint in self.constraints) {
    BOOL isWidthOrHeight =
    (constraint.firstAttribute == NSLayoutAttributeWidth) ||
    (constraint.firstAttribute == NSLayoutAttributeHeight);
    
    if ([self.subviews containsObject:constraint.firstItem] &&
        [self.subviews containsObject:constraint.secondItem] &&
        !isWidthOrHeight) {
      constraint.constant = spacing;
    }
  }
}

- (void)setAxis:(UILayoutConstraintAxis)axis {
  if (_axis == axis) { return; }
  
  _axis = axis;
  _alignmentStrategy = [OAStackViewAlignmentStrategy strategyWithStackView:self];
  
  [self layoutArrangedViews];
}

- (void)setAxisValue:(NSInteger)axisValue {
  _axisValue = axisValue;
  self.axis = self.axisValue;
}

- (void)setAlignment:(OAStackViewAlignment)alignment {
  if (_alignment == alignment) { return; }
  
  _alignment = alignment;
  [self setAlignmentConstraints];
}

- (void)setAlignmentConstraints {
  [self.alignmentStrategy removeAddedConstraints];
  self.alignmentStrategy = [OAStackViewAlignmentStrategy strategyWithStackView:self];
  
  [self.alignmentStrategy alignFirstView:self.subviews.firstObject];
  
  [self iterateVisibleViews:^(UIView *view, UIView *previousView) {
    [self.alignmentStrategy addConstraintsOnOtherAxis:view];
    [self.alignmentStrategy alignView:view withPreviousView:previousView];
  }];
  
  [self.alignmentStrategy alignLastView:self.subviews.lastObject];
}

- (void)removeConstraint:(NSLayoutConstraint *)constraint {
  [super removeConstraint:constraint];
}

- (void)removeConstraints:(NSArray<__kindof NSLayoutConstraint *> *)constraints {
  [super removeConstraints:constraints];
}

- (void)updateConstraints {
  [super updateConstraints];
}

- (void)layoutSubviews {
  [super layoutSubviews];
}

- (void)setAlignmentValue:(NSInteger)alignmentValue {
  _alignmentValue = alignmentValue;
  self.alignment = alignmentValue;
}

- (void)setDistribution:(OAStackViewDistribution)distribution {
  if (_distribution == distribution) { return; }
  
  _distribution = distribution;
  [self setAlignmentConstraints];
  [self setDistributionConstraints];
}

- (void)setDistributionConstraints {
  [self.distributionStrategy removeAddedConstraints];
  
  self.distributionStrategy = [OAStackViewDistributionStrategy strategyWithStackView:self];
  
  [self iterateVisibleViews:^(UIView *view, UIView *previousView) {
    [self.distributionStrategy alignView:view afterView:previousView];
  }];
  
  [self.distributionStrategy alignView:nil afterView:[self lastVisibleItem]];
}

- (void)setDistributionValue:(NSInteger)distributionValue {
  _distributionValue = distributionValue;
  self.distribution = distributionValue;
}

- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins {
    _layoutMargins = layoutMargins;
    [self layoutArrangedViews];
}

- (void)setLayoutMarginsRelativeArrangement:(BOOL)layoutMarginsRelativeArrangement {
    _layoutMarginsRelativeArrangement = layoutMarginsRelativeArrangement;
    [self layoutArrangedViews];
}

#pragma mark - Overriden methods

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self layoutArrangedViews];
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    [self addObserverForView:subview];
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    [self removeObserverForView:subview];
}


#pragma mark - Adding and removing

- (void)addArrangedSubview:(UIView *)view {
  [self insertArrangedSubview:view atIndex:self.subviews.count];
}

- (void)removeArrangedSubview:(UIView *)view {
  
  if (self.subviews.count == 1) {
    [self.mutableArrangedSubviews removeObject:view];
    [view removeFromSuperview];
    return;
  }
  
  [self removeViewFromArrangedViews:view permanently:YES];
}

- (void)insertArrangedSubview:(UIView *)view atIndex:(NSUInteger)stackIndex {
  [self insertArrangedSubview:view atIndex:stackIndex newItem:YES];
}

- (void)insertArrangedSubview:(UIView *)view atIndex:(NSUInteger)stackIndex newItem:(BOOL)newItem {
  
  id previousView, nextView;
  view.translatesAutoresizingMaskIntoConstraints = NO;
  BOOL isAppending = stackIndex == self.subviews.count;
  
  if (isAppending) {
    //Appending a new item
    
    previousView = [self lastVisibleItem];
    nextView = nil;
    
    NSArray<__kindof NSLayoutConstraint *> *constraints = [self lastConstraintAffectingView:self andView:previousView inAxis:self.axis];
    if (constraints) {
      [self removeConstraints:constraints];
    }
    
    if (newItem) {
      [self.mutableArrangedSubviews addObject:view];
      [self addSubview:view];
    }
    
  } else {
    //Item insertion
    
    previousView = [self visibleViewBeforeIndex:stackIndex];
    nextView = [self visibleViewAfterIndex:newItem ? stackIndex - 1: stackIndex];
    
    NSArray<__kindof NSLayoutConstraint *> *constraints;
    BOOL isLastVisibleItem = [self isViewLastItem:previousView excludingItem:view];
    BOOL isFirstVisibleView = previousView == nil;
    BOOL isOnlyItem = previousView == nil && nextView == nil;
    
    if (isLastVisibleItem) {
      constraints = @[[self lastViewConstraint]];
    } else if(isOnlyItem) {
      constraints = [self constraintsBetweenView:previousView ?: self andView:nextView ?: self inAxis:self.axis];
    } else if(isFirstVisibleView) {
      constraints = @[[self firstViewConstraint]];
    } else {
      constraints = [self constraintsBetweenView:previousView ?: self andView:nextView ?: self inAxis:self.axis];
    }
    
    [self removeConstraints:constraints];
    
    if (newItem) {
      [self.mutableArrangedSubviews insertObject:view atIndex:stackIndex];
      [self insertSubview:view atIndex:stackIndex];
    }
  }
  
  [self.distributionStrategy alignView:view afterView:previousView];
  [self.alignmentStrategy alignView:view withPreviousView:previousView];
  [self.alignmentStrategy addConstraintsOnOtherAxis:view];
  [self.distributionStrategy alignView:nextView afterView:view];
  [self.alignmentStrategy alignView:nextView withPreviousView:view];
}

- (void)removeViewFromArrangedViews:(UIView*)view permanently:(BOOL)permanently {
  NSInteger index = [self.subviews indexOfObject:view];
  if (index == NSNotFound) { return; }
  
  id previousView = [self visibleViewBeforeView:view];
  id nextView = [self visibleViewAfterView:view];
  
  if (permanently) {
    [self.mutableArrangedSubviews removeObject:view];
    [view removeFromSuperview];
  } else {
    NSArray <__kindof NSLayoutConstraint *> *constraint = [self constraintsAffectingView:view];
    [self removeConstraints:constraint];
  }
  
  if (nextView) {
    [self.distributionStrategy alignView:nextView afterView:previousView];
  } else if(previousView) {
    [self.distributionStrategy alignView:nil afterView:[self lastVisibleItem]];
  }
}

#pragma mark - Hide and Unhide

- (void)hideView:(UIView*)view {
  [self removeViewFromArrangedViews:view permanently:NO];
}

- (void)unHideView:(UIView*)view {
  NSInteger index = [self.subviews indexOfObject:view];
  [self insertArrangedSubview:view atIndex:index newItem:NO];
}

#pragma mark - Align View

- (void)layoutArrangedViews {
  [self removeDecendentConstraints];

  [self setAlignmentConstraints];
  [self setDistributionConstraints];
}

- (void)addViewsAsSubviews:(NSArray*)views {
  for (UIView *view in views) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:view];
  }
}

@end

#pragma mark - Runtime Injection

// Constructors are called after all classes have been loaded.
__attribute__((constructor)) static void OAStackViewPatchEntry(void) {
    
    if (objc_getClass("UIStackView")) {
        return;
    }
    
    if (objc_getClass("OAStackViewDisableForwardToUIStackViewSentinel")) {
        return;
    }
    
    Class class = objc_allocateClassPair(OAStackView.class, "UIStackView", 0);
    if (class) {
        objc_registerClassPair(class);
    }
}
