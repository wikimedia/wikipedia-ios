//
//  WMFDateFormatterTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSDateFormatter+WMFExtensions.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFDateFormatterTests : XCTestCase

@end

@implementation WMFDateFormatterTests

- (void)testIso8601Example {
    NSString* testTimestamp   = @"2015-02-10T10:31:27Z";
    NSDate* decodedDate = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:testTimestamp];
    assertThat(decodedDate, is(notNilValue()));
    assertThat([[NSDateFormatter wmf_iso8601Formatter] stringFromDate:decodedDate], is(equalTo(testTimestamp)));
}

- (void)testShortTimeFormatterIsValidForAllLocales {
    NSString* testTimestamp = @"2015-02-10T10:31:27Z";
    NSArray* availableLocaleIDs = [NSLocale availableLocaleIdentifiers];

    dispatch_apply(availableLocaleIDs.count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
        NSString* localeID = availableLocaleIDs[i];
        NSLocale* locale = [NSLocale localeWithLocaleIdentifier:localeID];

        // need to parse date using the "regular" formatter
        NSDate* decodedDate = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:testTimestamp];
        NSParameterAssert(decodedDate);

        // TODO: check for "AM" for corresponding time locales
        assertThat([[NSDateFormatter wmf_shortTimeFormatterWithLocale:locale] stringFromDate:decodedDate],
                   describedAs(@"expected non-nil for locale: %0 from timestamp %1",
                               notNilValue(),
                               localeID,
                               testTimestamp,
                               nil));
    });
}

- (void)testShortTimeFormatterExamples {
    NSString* testTimestamp = @"2015-02-10T14:31:27Z";
    NSDate* decodedDate = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:testTimestamp];
    NSParameterAssert(decodedDate);

    NSDateFormatter* usFormatter =
        [NSDateFormatter wmf_shortTimeFormatterWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];

    NSDateFormatter* gbFormatter =
         [NSDateFormatter wmf_shortTimeFormatterWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_GB"]];

    assertThat([usFormatter stringFromDate:decodedDate], is(equalTo(@"2:31 PM")));

    assertThat([gbFormatter stringFromDate:decodedDate], is(equalTo(@"14:31")));
}

@end
