#import <XCTest/XCTest.h>

@interface WMFNotificationTests : XCTestCase

@property (nonnull, nonatomic, strong) WMFFeedContentSource *feedContentSource;
@property (nonnull, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;
@property (nonnull, nonatomic, strong) WMFContentGroupDataStore *contentStore;

@end

@implementation WMFNotificationTests

- (void)setUp {
    [super setUp];
    NSURL *siteURL = [NSURL URLWithString:@"https://en.wikipedia.org"];
    self.previewStore = [[WMFArticlePreviewDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
    self.contentStore = [[WMFContentGroupDataStore alloc] initWithDatabase:[YapDatabase sharedInstance]];
    self.feedContentSource = [[WMFFeedContentSource alloc] initWithSiteURL:siteURL contentGroupDataStore:self.contentStore articlePreviewDataStore:self.previewStore userDataStore:[SessionSingleton sharedInstance].dataStore notificationsController:[WMFNotificationsController sharedNotificationsController]];
}

- (void)testNotifiesWhenMostRecentDateIsMoreThanThreeDaysAgo {
    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];
    NSDate *now = [NSDate date];
    NSDate *daysAgo = [calendar dateByAddingUnit:NSCalendarUnitDay value:-4 toDate:now options:NSCalendarMatchStrictly];
    NSUserDefaults *defaults = [NSUserDefaults wmf_userDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:daysAgo];
    XCTAssertTrue([calendar daysFromDate:[defaults wmf_mostRecentInTheNewsNotificationDate] toDate:now] >= 3);
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadNewContentForce:YES
                                     completion:^{
                                         NSDate *notificationDate = [defaults wmf_mostRecentInTheNewsNotificationDate];
                                         XCTAssertTrue([calendar isDateInToday:notificationDate] || [calendar daysFromDate:now toDate:notificationDate] <= 1);
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
