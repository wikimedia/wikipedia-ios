#import <XCTest/XCTest.h>
#import <Nocilla/LSNocilla.h>

@interface WMFNotificationTests : XCTestCase

@property (nonnull, nonatomic, strong) WMFFeedContentSource *feedContentSource;
@property (nonnull, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;
@property (nonnull, nonatomic, strong) WMFContentGroupDataStore *contentStore;

@property (nonnull, nonatomic, strong) NSCalendar *calendar;
@property (nonnull, nonatomic, strong) NSDate *date;
@property (nonnull, nonatomic, strong) NSURL *feedURL;

@end

@implementation WMFNotificationTests

- (void)setUp {
    [super setUp];
    NSURL *siteURL = [NSURL URLWithString:@"https://en.wikipedia.org"];
    self.previewStore = [[WMFArticlePreviewDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
    self.contentStore = [[WMFContentGroupDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
    self.feedContentSource = [[WMFFeedContentSource alloc] initWithSiteURL:siteURL contentGroupDataStore:self.contentStore articlePreviewDataStore:self.previewStore userDataStore:[SessionSingleton sharedInstance].dataStore notificationsController:[WMFNotificationsController sharedNotificationsController]];

    self.calendar = [NSCalendar wmf_gregorianCalendar];
    self.date = [NSDate date];

    [[LSNocilla sharedInstance] start];
    self.feedURL = [WMFFeedContentFetcher feedContentURLForSiteURL:siteURL onDate:self.date];
    NSData *feedJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MCSFeedTopReadNewsItem" ofType:@"json"];
    stubRequest(@"GET", self.feedURL.absoluteString).andReturn(200).withHeaders(@{ @"Content-Type": @"application/json" }).withBody(feedJSONData);

    NSData *pageViewJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"PageViews" ofType:@"json"];
    NSRegularExpression *anyPageViewRequest = [NSRegularExpression regularExpressionWithPattern:@"https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia.org/all-access/.*" options:0 error:nil];
    stubRequest(@"GET", anyPageViewRequest)
        .andReturn(200)
        .withHeaders(@{ @"Content-Type": @"application/json" })
        .withBody(pageViewJSONData);

    UIImage *testImage = [UIImage imageNamed:@"golden-gate.jpg" inBundle:[self wmf_bundle] compatibleWithTraitCollection:nil];
    NSRegularExpression *anyThumbRequest = [NSRegularExpression regularExpressionWithPattern:@"https://upload.wikimedia.org/wikipedia/commons/thumb/.*" options:0 error:nil];
    stubRequest(@"GET", anyThumbRequest).andReturnRawResponse(UIImageJPEGRepresentation(testImage, 0));
}

- (void)tearDown {
    [super tearDown];
    [[LSNocilla sharedInstance] stop];
}

- (void)testNotifiesWhenMostRecentDateIsMoreThanThreeDaysAgo {
    NSData *feedJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MCSFeed" ofType:@"json"];
    stubRequest(@"GET", self.feedURL.absoluteString).andReturn(200).withHeaders(@{ @"Content-Type": @"application/json" }).withBody(feedJSONData); // News item isn't in top read - test force notify

    NSDate *now = [NSDate date];
    NSDate *daysAgo = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:-4 toDate:now options:NSCalendarMatchStrictly];
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:daysAgo];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:4];

    XCTAssertTrue([self.calendar daysFromDate:[defaults wmf_mostRecentInTheNewsNotificationDate] toDate:now] >= 3);
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                                         force:NO
                                    completion:^{
                                        NSDate *notificationDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
                                        XCTAssertTrue([self.calendar isDateInToday:notificationDate] || [self.calendar daysFromDate:now toDate:notificationDate] == 1);
                                        XCTAssertTrue([defaults wmf_inTheNewsMostRecentDateNotificationCount] == 1);
                                        [expectation fulfill];
                                    }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)testIncrementsNotificationCount {
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:2];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                                         force:YES
                                    completion:^{
                                        XCTAssertTrue([defaults wmf_inTheNewsMostRecentDateNotificationCount] == 3);
                                        [expectation fulfill];
                                    }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)testDoesntIncrementNotificationCount {
    NSData *feedJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MCSFeed" ofType:@"json"];
    stubRequest(@"GET", self.feedURL.absoluteString).andReturn(200).withHeaders(@{ @"Content-Type": @"application/json" }).withBody(feedJSONData); // News item isn't in top read - test skip notify

    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:2];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                                         force:YES
                                    completion:^{
                                        XCTAssertTrue([defaults wmf_inTheNewsMostRecentDateNotificationCount] == 2);
                                        [expectation fulfill];
                                    }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)testDoesntNotifyWhenHaveNotifiedThreeTimes {
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:3];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                                         force:YES
                                    completion:^{
                                        XCTAssertTrue([defaults wmf_inTheNewsMostRecentDateNotificationCount] == 3);
                                        [expectation fulfill];
                                    }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

@end
