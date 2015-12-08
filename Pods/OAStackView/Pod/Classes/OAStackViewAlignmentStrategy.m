//
//  OAStackViewAlignmentStrategy.m
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import "OAStackViewAlignmentStrategy.h"
#import "OAStackViewAlignmentStrategyBaseline.h"


@interface OAStackViewAlignmentStrategyFill : OAStackViewAlignmentStrategy
@end

@interface OAStackViewAlignmentStrategyTrailing : OAStackViewAlignmentStrategy
@end

@interface OAStackViewAlignmentStrategyLeading : OAStackViewAlignmentStrategy
@end

@interface OAStackViewAlignmentStrategyCenter: OAStackViewAlignmentStrategy
@end

@interface OAStackViewAlignmentStrategy ()
@property(nonatomic, weak) OAStackView *stackView;
@property(nonatomic) NSMutableArray *constraints;
@end

@implementation OAStackViewAlignmentStrategy

+ (OAStackViewAlignmentStrategy*)strategyWithStackView:(OAStackView *)stackView {
  
  Class cls;
  switch (stackView.alignment) {

    case OAStackViewAlignmentFill:
      cls = [OAStackViewAlignmentStrategyFill class];
      break;
      
    case OAStackViewAlignmentLeading:
      cls = [OAStackViewAlignmentStrategyLeading class];
      break;
      
    case OAStackViewAlignmentTrailing:
      cls = [OAStackViewAlignmentStrategyTrailing class];
      break;
      
    case OAStackViewAlignmentCenter:
      cls = [OAStackViewAlignmentStrategyCenter class];
      break;
          
    case OAStackViewAlignmentBaseline:
      cls = [OAStackViewAlignmentStrategyLastBaseline class];
      break;
          
    case OAStackViewAlignmentFirstBaseline:
      cls = [OAStackViewAlignmentStrategyFirstBaseline class];
      break;
          
    default:
      break;
  }
  
  return [[cls alloc] initWithWithStackView:stackView];
}

- (instancetype)initWithWithStackView:(OAStackView *)stackView {
  self = [super init];
  if (self) {
    _stackView = stackView;;
  }
  return self;
}

- (NSString*)otherAxisString {
  return self.stackView.axis == UILayoutConstraintAxisHorizontal ? @"V" : @"H";
}

- (CGFloat)firstMargin {
    if (self.stackView.axis == UILayoutConstraintAxisHorizontal) {
        return self.stackView.layoutMarginsRelativeArrangement ? self.stackView.layoutMargins.top : 0.0f;
    } else {
        return self.stackView.layoutMarginsRelativeArrangement ? self.stackView.layoutMargins.left : 0.0f;
    }
}

- (CGFloat)lastMargin {
    if (self.stackView.axis == UILayoutConstraintAxisHorizontal) {
        return self.stackView.layoutMarginsRelativeArrangement ? self.stackView.layoutMargins.bottom : 0.0f;
    } else {
        return self.stackView.layoutMarginsRelativeArrangement ? self.stackView.layoutMargins.right : 0.0f;
    }
}

- (NSLayoutAttribute)centerAttribute {
  return self.stackView.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeCenterY : NSLayoutAttributeCenterX;
}

- (void)addConstraintsOnOtherAxis:(UIView*)view {
  id arr = [self constraintsalignViewOnOtherAxis:view];
  [self.constraints addObjectsFromArray:arr];
  
  if (arr) { [self.stackView addConstraints:arr]; }
}

- (void)alignView:(UIView*)view withPreviousView:(UIView*)previousView {
  id arr = [self constraintsAlignView:view afterPreviousView:previousView];
  [self.constraints addObjectsFromArray:arr];
  
  if (arr) { [self.stackView addConstraints:arr]; }
}

- (NSMutableArray *)constraints {
  if (!_constraints) {
    _constraints = [@[] mutableCopy];
  }
  
  return _constraints;
}

- (void)removeAddedConstraints {
  [self.stackView removeConstraints:self.constraints];
  [self.constraints removeAllObjects];
}

- (NSArray*)constraintsalignViewOnOtherAxis:(UIView*)view {
    id constraintString = [NSString stringWithFormat:@"%@:|-(%@firstMargin)-[view]-(%@lastMargin)-|", [self otherAxisString], [self firstMarginRelation], [self lastMarginRelation]];

    NSNumber *firstMargin = @([self firstMargin]);
    NSNumber *lastMargin = @([self lastMargin]);
    return [NSLayoutConstraint constraintsWithVisualFormat:constraintString
                                                   options:0
                                                   metrics:NSDictionaryOfVariableBindings(firstMargin, lastMargin)
                                                     views:NSDictionaryOfVariableBindings(view)];
}

- (NSArray*)constraintsAlignView:(UIView *)view afterPreviousView:(UIView*)afterView { /* subclassing */ return nil; }

- (NSString *)firstMarginRelation {
    return @"==";
}

- (NSString *)lastMarginRelation {
    return @"==";
}

- (void)alignFirstView:(UIView*)view {
  if(!view) { return; }
  id arr = [self firstViewConstraints:view withParentView:self.stackView];
  if(!arr) { return; }
  
  [self.constraints addObjectsFromArray:arr];
  if (arr) { [self.stackView addConstraints:arr]; }
}

- (void)alignLastView:(UIView*)view {
  if(!view) { return; }
  id arr = [self lastViewConstraints:view withParentView:self.stackView];
  if(!arr) { return; }
  
  [self.constraints addObjectsFromArray:arr];
  if (arr) { [self.stackView addConstraints:arr]; }
}

- (NSArray*)firstViewConstraints:(UIView*)view withParentView:(UIView*)parentView {
  return nil;
}

- (NSArray*)lastViewConstraints:(UIView*)view withParentView:(UIView*)parentView {
  return nil;
}

@end

@implementation OAStackViewAlignmentStrategyFill
@end

@implementation OAStackViewAlignmentStrategyLeading
- (NSString *)firstMarginRelation {
    return @"==";
}

- (NSString *)lastMarginRelation {
    return @">=";
}
@end

@implementation OAStackViewAlignmentStrategyTrailing
- (NSString *)firstMarginRelation {
    return @">=";
}

- (NSString *)lastMarginRelation {
    return @"==";
}
@end

@implementation OAStackViewAlignmentStrategyCenter
- (NSString *)firstMarginRelation {
    return @">=";
}

- (NSString *)lastMarginRelation {
    return @">=";
}

- (NSArray*)constraintsalignViewOnOtherAxis:(UIView*)view {
    NSArray<__kindof NSLayoutConstraint *> *constraints = [super constraintsalignViewOnOtherAxis:view];
    CGFloat centerAdjustment = ([self firstMargin] - [self lastMargin]) / 2;
    return [constraints arrayByAddingObject:[NSLayoutConstraint constraintWithItem:view
                                                                         attribute:[self centerAttribute]
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:view.superview
                                                                         attribute:[self centerAttribute]
                                                                        multiplier:1
                                                                          constant:centerAdjustment]];
}

@end
