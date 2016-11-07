#import <XCTest/XCTest.h>
#import <Nocilla/LSNocilla.h>

@interface WMFNotificationTests : XCTestCase

@property (nonnull, nonatomic, strong) WMFFeedContentSource *feedContentSource;
@property (nonnull, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;
@property (nonnull, nonatomic, strong) WMFContentGroupDataStore *contentStore;

@property (nonnull, nonatomic, strong) NSCalendar *calendar;
@property (nonnull, nonatomic, strong) NSDate *date;

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
    NSURL *feedURL = [WMFFeedContentFetcher feedContentURLForSiteURL:siteURL onDate:self.date];
    
    NSData *feedJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MCSFeed" ofType:@"json"];
    stubRequest(@"GET", feedURL.absoluteString).andReturn(200).withHeaders(@{@"Content-Type": @"application/json" }).withBody(feedJSONData);
    
    NSData *pageViewJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"PageViews" ofType:@"json"];
    NSRegularExpression *anyPageViewRequest = [NSRegularExpression regularExpressionWithPattern:@"https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia.org/all-access/.*" options:0 error:nil];
    stubRequest(@"GET", anyPageViewRequest)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(pageViewJSONData);
    
}

- (void)tearDown {
    [super tearDown];
    [[LSNocilla sharedInstance] stop];
}

- (void)testNotifiesWhenMostRecentDateIsMoreThanThreeDaysAgo {
    NSDate *now = [NSDate date];
    NSDate *daysAgo = [self.calendar dateByAddingUnit:NSCalendarUnitDay value:-4 toDate:now options:NSCalendarMatchStrictly];
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:daysAgo];
    XCTAssertTrue([self.calendar daysFromDate:[defaults wmf_mostRecentInTheNewsNotificationDate] toDate:now] >= 3);
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                                    completion:^{
                                         NSDate *notificationDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
                                         XCTAssertTrue([self.calendar isDateInToday:notificationDate] || [self.calendar daysFromDate:now toDate:notificationDate] == 1);
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
