//
//  OAStackViewDistributionStrategy.h
//  Pods
//
//  Created by Omar Abdelhafith on 15/06/2015.
//
//

#import <UIKit/UIKit.h>
#import "OAStackView.h"


@interface OAStackViewDistributionStrategy : NSObject

+ (OAStackViewDistributionStrategy*)strategyWithStackView:(OAStackView *)stackView;

- (void)alignView:(UIView*)view afterView:(UIView*)previousView;
- (void)removeAddedConstraints;

@end
