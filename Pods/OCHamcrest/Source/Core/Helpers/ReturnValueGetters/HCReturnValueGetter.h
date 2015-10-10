//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 hamcrest.org. See LICENSE.txt

#import <Foundation/Foundation.h>


/*!
 * @brief Chain-of-responsibility for handling NSInvocation return types.
 */
@interface HCReturnValueGetter : NSObject

- (instancetype)initWithType:(char const *)handlerType successor:(HCReturnValueGetter *)successor;
- (id)returnValueOfType:(char const *)type fromInvocation:(NSInvocation *)invocation;

@end
