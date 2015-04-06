//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import <Foundation/Foundation.h>


@interface MKTDynamicProperties : NSObject

- (instancetype)initWithClass:(Class)aClass;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;

@end
