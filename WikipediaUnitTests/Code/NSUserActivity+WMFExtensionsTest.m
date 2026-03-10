#import <XCTest/XCTest.h>
#import "NSUserActivity+WMFExtensions.h"

@interface NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test : XCTestCase
@end

@implementation NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test

- (void)testURLWithoutWikipediaSchemeReturnsNil {
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testInvalidArticleURLReturnsNil {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/Foo"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertNil(activity);
}

- (void)testArticleURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/wiki/Foo"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeLink);
    XCTAssertEqualObjects(activity.webpageURL.absoluteString, @"https://en.wikipedia.org/wiki/Foo");
}

- (void)testExploreURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://explore"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeExplore);
}

- (void)testSavedURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://saved"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeSavedPages);
}

- (void)testSearchURL {
    NSURL *url = [NSURL URLWithString:@"wikipedia://en.wikipedia.org/w/index.php?search=dog"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];
    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypeLink);
    XCTAssertEqualObjects(activity.webpageURL.absoluteString,
                          @"https://en.wikipedia.org/w/index.php?search=dog&title=Special:Search&fulltext=1");
}

- (void)testPlacesURLWithPlaceNameAndCoordinates {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?name=Amsterdam&latitude=1.2345&longitude=-2.4567"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertEqualObjects(activity.userInfo[@"WMFPlacesName"], @"Amsterdam");
    XCTAssertEqualObjects(activity.userInfo[@"WMFPlacesLatitude"], @"1.2345");
    XCTAssertEqualObjects(activity.userInfo[@"WMFPlacesLongitude"], @"-2.4567");
}

- (void)testPlacesURLWithoutName {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?latitude=1.2345&longitude=-2.4567"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.userInfo[@"WMFPlacesName"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLatitude"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLongitude"]);
}

- (void)testPlacesURLWithoutLatitude {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?name=Amsterdam&longitude=-2.4567"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.userInfo[@"WMFPlacesName"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLatitude"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLongitude"]);
}

- (void)testPlacesURLWithoutLongitude {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?name=Amsterdam&latitude=1.2345"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.userInfo[@"WMFPlacesName"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLatitude"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLongitude"]);
}

- (void)testPlacesURLWithNameOnly {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?name=Amsterdam"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.userInfo[@"WMFPlacesName"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLatitude"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLongitude"]);
}

- (void)testPlacesURLWithLatitudeOnly {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?latitude=1.2345"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.userInfo[@"WMFPlacesName"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLatitude"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLongitude"]);
}

- (void)testPlacesURLWithLongitudeOnly {
    NSURL *url = [NSURL URLWithString:@"wikipedia://places?longitude=-2.4567"];
    NSUserActivity *activity = [NSUserActivity wmf_activityForWikipediaScheme:url];

    XCTAssertEqual(activity.wmf_type, WMFUserActivityTypePlaces);
    XCTAssertNil(activity.userInfo[@"WMFPlacesName"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLatitude"]);
    XCTAssertNil(activity.userInfo[@"WMFPlacesLongitude"]);
}

@end
