//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2016 Jonathan M. Reid. See LICENSE.txt

#import <Foundation/Foundation.h>
#import "MKTNonObjectArgumentMatching.h"


@interface MKTBaseMockObject : NSProxy <MKTNonObjectArgumentMatching>

+ (BOOL)isMockObject:(id)object;

- (instancetype)init;
- (void)mkt_stopMocking;

@end
