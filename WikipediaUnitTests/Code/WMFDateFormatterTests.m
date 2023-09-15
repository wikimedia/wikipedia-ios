#import <XCTest/XCTest.h>
#import "NSDateFormatter+WMFExtensions.h"
#import "XCTestCase+WMFLocaleTesting.h"

@interface WMFDateFormatterTests : XCTestCase

@end

@implementation WMFDateFormatterTests

- (void)testIso8601Example {
    NSString *testTimestamp = @"2015-02-10T10:31:27Z";
    NSDate *decodedDate = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:testTimestamp];
    XCTAssertNotNil(decodedDate);
    XCTAssertEqualObjects([[NSDateFormatter wmf_iso8601Formatter] stringFromDate:decodedDate], testTimestamp);
}

- (void)testShortTimeFormatterIsValidForAllLocales {
    NSString *testTimestamp = @"2015-02-10T10:31:27Z";
    [self wmf_runParallelTestsWithLocales:[NSLocale availableLocaleIdentifiers]
                                    block:^(NSLocale *locale, XCTestExpectation *e) {
                                        // need to parse date using the "regular" formatter
                                        NSDate *decodedDate = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:testTimestamp];
                                        NSParameterAssert(decodedDate);

                                        // TODO: check for "AM" for corresponding time locales
                                        XCTAssertNotNil([[NSDateFormatter wmf_shortTimeFormatterWithLocale:locale] stringFromDate:decodedDate]);
                                        [e fulfill];
                                    }];
}

- (void)testShortTimeFormatterExamples {
    NSString *testTimestamp = @"2015-02-10T14:31:27Z";
    NSDate *decodedDate = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:testTimestamp];
    NSParameterAssert(decodedDate);

    NSDateFormatter *usFormatter =
        [NSDateFormatter wmf_shortTimeFormatterWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];

    NSDateFormatter *gbFormatter =
        [NSDateFormatter wmf_shortTimeFormatterWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_GB"]];

    if (@available(iOS 17, *)) {
        XCTAssertEqualObjects([usFormatter stringFromDate:decodedDate], @"2:31 PM");
    } else {
        XCTAssertEqualObjects([usFormatter stringFromDate:decodedDate], @"2:31 PM");
    }
    
    XCTAssertEqualObjects([gbFormatter stringFromDate:decodedDate], @"14:31");
}

@end
