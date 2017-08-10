#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "NSMutableDictionary+WMFMaybeSet.h"

@interface NSMutableDictionary_WMFMaybeSetTests : XCTestCase

@end

@implementation NSMutableDictionary_WMFMaybeSetTests

- (void)testNotNil {
    NSMutableDictionary *testDict = [NSMutableDictionary new];
    assertThat(@([testDict wmf_maybeSetObject:@"foo" forKey:@"bar"]), is(@YES));
    assertThat(testDict, is(equalTo(@{@"bar": @"foo"})));
    assertThat(@([testDict wmf_maybeSetObject:@"biz" forKey:@"bar"]), is(@YES));
    assertThat(testDict, is(equalTo(@{@"bar": @"biz"})));
}

- (void)testNil {
    NSMutableDictionary *testDict = [NSMutableDictionary new];
    assertThat(@([testDict wmf_maybeSetObject:nil forKey:@"bar"]), is(@NO));
    assertThat(testDict, isEmpty());
}

@end
