//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import <Foundation/Foundation.h>

@class MKTVerificationData;


@protocol MKTVerificationMode <NSObject>

- (void)verifyData:(MKTVerificationData *)data;

@end
