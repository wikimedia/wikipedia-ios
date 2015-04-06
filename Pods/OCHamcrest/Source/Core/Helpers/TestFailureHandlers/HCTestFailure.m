//  OCHamcrest by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2014 hamcrest.org. See LICENSE.txt

#import "HCTestFailure.h"


@implementation HCTestFailure

- (instancetype)initWithTestCase:(id)testCase
                        fileName:(NSString *)fileName
                      lineNumber:(NSUInteger)lineNumber
                          reason:(NSString *)reason
{
    self = [super init];
    if (self)
    {
        _testCase = testCase;
        _fileName = [fileName copy];
        _lineNumber = lineNumber;
        _reason = [reason copy];
    }
    return self;
}

@end
