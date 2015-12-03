//
//  OAStackView+Constraint.h
//  Pods
//
//  Created by Omar Abdelhafith on 14/06/2015.
//
//

#import <OAStackView/OAStackView.h>

@interface OAStackView (Constraint)

- (NSArray*)constraintsAffectingView:(UIView*)view;
- (NSArray*)constraintsAffectingView:(UIView*)view inAxis:(UILayoutConstraintAxis)axis;

- (NSArray*)constraintsBetweenView:(UIView*)firstView andView:(UIView*)otherView inAxis:(UILayoutConstraintAxis)axis;
- (NSArray*)constraintsBetweenView:(UIView*)firstView andView:(UIView*)otherView
                            inAxis:(UILayoutConstraintAxis)axis includeReversed:(BOOL)includeReversed;

- (void)removeDecendentConstraints;

- (NSArray*)firstConstraintAffectingView:(UIView*)superView andView:(UIView*)childView inAxis:(UILayoutConstraintAxis)axis;
- (NSArray*)lastConstraintAffectingView:(UIView*)superView andView:(UIView*)childView inAxis:(UILayoutConstraintAxis)axis;

@end
