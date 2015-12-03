//
//  OAStackViewAlignmentStrategyBaseline.h
//  
//
//  Created by Omar Abdelhafith on 08/08/2015.
//
//

#import <Foundation/Foundation.h>
#import "OAStackViewAlignmentStrategy.h"


@interface OAStackViewAlignmentStrategyBaseline: OAStackViewAlignmentStrategy
- (NSLayoutAttribute)baselineAttribute;
@end

@interface OAStackViewAlignmentStrategyLastBaseline: OAStackViewAlignmentStrategyBaseline
@end

@interface OAStackViewAlignmentStrategyFirstBaseline: OAStackViewAlignmentStrategyBaseline
@end

