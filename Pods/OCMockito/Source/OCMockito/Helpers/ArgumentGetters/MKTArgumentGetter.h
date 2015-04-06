//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import <Foundation/Foundation.h>


@interface MKTArgumentGetter : NSObject

- (instancetype)initWithType:(char const *)handlerType successor:(MKTArgumentGetter *)successor;
- (id)retrieveArgumentAtIndex:(NSInteger)idx ofType:(char const *)type onInvocation:(NSInvocation *)invocation;

@end
