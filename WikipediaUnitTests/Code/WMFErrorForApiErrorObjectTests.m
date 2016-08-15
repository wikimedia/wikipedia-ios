//
//  WMFErrorForApiErrorObjectTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "WMFNetworkUtilities.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFErrorForApiErrorObjectTests : XCTestCase

@end

@implementation WMFErrorForApiErrorObjectTests

- (void)testExample {
    NSDictionary *apiErrorObj = @{
        @"code" : @"badcontinue",
        @"info" : @"Invalid continue param. You should pass the original value returned by the previous query",
        @"*" : @"See https://en.wikipedia.org/w/api.php for API usage"
    };
    assertThat(WMFErrorForApiErrorObject(apiErrorObj),
               allOf(hasProperty(@"domain", WMFNetworkingErrorDomain),
                     hasProperty(@"userInfo", hasEntries(NSLocalizedFailureReasonErrorKey, apiErrorObj[@"code"],
                                                         NSLocalizedDescriptionKey, apiErrorObj[@"info"],
                                                         NSLocalizedRecoverySuggestionErrorKey, apiErrorObj[@"*"],
                                                         nil)),
                     nil));
}

- (void)testMissingFields {
    assertThat(WMFErrorForApiErrorObject(@{}),
               allOf(hasProperty(@"domain", WMFNetworkingErrorDomain),
                     hasProperty(@"userInfo", isEmpty()),
                     nil));
}

- (void)testNil {
    assertThat(WMFErrorForApiErrorObject(nil), is(nilValue()));
}

@end
