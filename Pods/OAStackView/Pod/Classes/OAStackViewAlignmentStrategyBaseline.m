//
//  OAStackViewAlignmentStrategyBaseline.m
//
//
//  Created by Omar Abdelhafith on 08/08/2015.
//
//

#import "OAStackViewAlignmentStrategyBaseline.h"


@implementation OAStackViewAlignmentStrategyBaseline

- (NSArray*)constraintsalignViewOnOtherAxis:(UIView*)view {
  id constraintString = [NSString stringWithFormat:@"%@:|-(>=0@750)-[view]-(>=0@750)-|", [self otherAxisString]];
  
  return [NSLayoutConstraint constraintsWithVisualFormat:constraintString
                                                 options:0
                                                 metrics:nil
                                                   views:NSDictionaryOfVariableBindings(view)];
}

- (NSArray*)constraintsAlignView:(UIView *)view afterPreviousView:(UIView*)afterView {
  if (!view  || !afterView) { return nil; }
  
  return @[[NSLayoutConstraint constraintWithItem:view
                                        attribute:[self baselineAttribute]
                                        relatedBy:NSLayoutRelationEqual toItem:afterView
                                        attribute:[self baselineAttribute] multiplier:1.0f
                                         constant:0.0f]];
}

- (NSArray*)firstViewConstraints:(UIView*)view withParentView:(UIView*)parentView {
  return nil;
  //Not used for now
//  id constraintString = [NSString stringWithFormat:@"%@:|-(>=0@750)-[view]", [self otherAxisString]];
//  
//  return [NSLayoutConstraint constraintsWithVisualFormat:constraintString
//                                                 options:0
//                                                 metrics:nil
//                                                   views:NSDictionaryOfVariableBindings(view)];
//  
//  return @[[NSLayoutConstraint constraintWithItem:parentView
//                                        attribute:NSLayoutAttributeTop
//                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
//                                           toItem:view
//                                        attribute:NSLayoutAttributeTop
//                                       multiplier:1 constant:0]];
}

- (NSArray*)lastViewConstraints:(UIView*)view withParentView:(UIView*)parentView {
  return nil;
  //Not used for now
//  id constraintString = [NSString stringWithFormat:@"%@:[view]-(>=0@750)-|", [self otherAxisString]];
//  
//  return [NSLayoutConstraint constraintsWithVisualFormat:constraintString
//                                                 options:0
//                                                 metrics:nil
//                                                   views:NSDictionaryOfVariableBindings(view)];
//  
//  return @[[NSLayoutConstraint constraintWithItem:parentView
//                                        attribute:NSLayoutAttributeBottom
//                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
//                                           toItem:view
//                                        attribute:NSLayoutAttributeBottom
//                                       multiplier:1 constant:0]];
}

- (NSLayoutAttribute)baselineAttribute {
  return NSLayoutAttributeBaseline;
}

@end


@implementation OAStackViewAlignmentStrategyFirstBaseline

- (NSLayoutAttribute)baselineAttribute {
  return NSLayoutAttributeFirstBaseline;
}

@end


@implementation OAStackViewAlignmentStrategyLastBaseline

- (NSLayoutAttribute)baselineAttribute {
  return NSLayoutAttributeLastBaseline;
}

@end
