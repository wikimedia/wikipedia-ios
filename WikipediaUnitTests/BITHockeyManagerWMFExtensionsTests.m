
#define HC_SHORTHAND 1
#define MOCKITO_SHORTHAND 1

#import <XCTest/XCTest.h>
#import <OCHamcrest/OCHamcrest.h>

#import "BITHockeyManager+WMFExtensions.h"


@interface BITHockeyManagerWMFExtensionsTests : XCTestCase

@end


@implementation BITHockeyManagerWMFExtensionsTests

- (void)testKnownBundleID {
    BOOL success = [[BITHockeyManager sharedHockeyManager] wmf_setAPIKeyForBundleID:@"org.wikimedia.wikipedia.tfalpha"];
    assertThat(@(success), is(isTrue()));
}

- (void)testUnknownBundleID {
    BOOL success = [[BITHockeyManager sharedHockeyManager] wmf_setAPIKeyForBundleID:@"org.wikimedia.wikipedia.garbage"];
    assertThat(@(success), is(isFalse()));
}

@end