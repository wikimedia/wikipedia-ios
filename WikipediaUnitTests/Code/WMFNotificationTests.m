#import <XCTest/XCTest.h>
#import "MWKDataStore+TemporaryDataStore.h"
#import <WMF/WMF.h>
#import "LSNocilla.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFRandomFileUtilities.h"
#import "NSUserDefaults+WMFReset.h"

@interface WMFNotificationTests : XCTestCase

@property (nonnull, nonatomic, strong) MWKDataStore *dataStore;

@property (nonnull, nonatomic, strong) WMFFeedContentSource *feedContentSource;

@property (nonnull, nonatomic, strong) NSCalendar *calendar;
@property (nonnull, nonatomic, strong) NSDate *date;
@property (nonatomic, getter=isScheduledForTomorrow) BOOL scheduledForTomorrow;
@property (nonnull, nonatomic, strong) NSURL *feedURL;

@end

@implementation WMFNotificationTests

- (void)setUp {
    [super setUp];

    [[NSUserDefaults standardUserDefaults] wmf_resetToDefaultValues];

    self.dataStore = [MWKDataStore temporaryDataStore];
    NSURL *siteURL = [NSURL URLWithString:@"https://en.wikipedia.org"];
    self.feedContentSource = [[WMFFeedContentSource alloc] initWithSiteURL:siteURL userDataStore:self.dataStore];
    self.feedContentSource.notificationSchedulingEnabled = YES;

    self.calendar = [NSCalendar wmf_gregorianCalendar];
    self.date = [NSDate date];

    NSDateComponents *dateComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.date];
    self.scheduledForTomorrow = dateComponents.hour > WMFFeedNotificationMaxHour;

    [[LSNocilla sharedInstance] start];
    self.feedURL = [WMFFeedContentFetcher feedContentURLForSiteURL:siteURL onDate:self.date configuration:[WMFConfiguration current]];
    NSData *feedJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MCSFeedTopReadNewsItem" ofType:@"json"];
    stubRequest(@"GET", self.feedURL.absoluteString).andReturn(200).withHeaders(@{@"Content-Type": @"application/json"}).withBody(feedJSONData);

    NSData *pageViewJSONData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"PageViews" ofType:@"json"];
    NSRegularExpression *anyPageViewRequest = [NSRegularExpression regularExpressionWithPattern:@".*v1/metrics/pageviews/per-article/en.wikipedia.org/all-access/.*" options:0 error:nil];
    stubRequest(@"GET", anyPageViewRequest)
        .andReturn(200)
        .withHeaders(@{@"Content-Type": @"application/json"})
        .withBody(pageViewJSONData);

    UIImage *testImage = [UIImage imageNamed:@"golden-gate.jpg" inBundle:[self wmf_bundle] compatibleWithTraitCollection:nil];
    NSRegularExpression *anyThumbRequest = [NSRegularExpression regularExpressionWithPattern:@"https://upload.wikimedia.org/wikipedia/commons/thumb/.*" options:0 error:nil];
    stubRequest(@"GET", anyThumbRequest).andReturnRawResponse(UIImageJPEGRepresentation(testImage, 0));
}

- (void)tearDown {
    [super tearDown];
    [[LSNocilla sharedInstance] stop];
}

- (void)testIncrementsNotificationCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:WMFFeedNotificationMaxPerDay - 1];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    NSInteger count = self.isScheduledForTomorrow ? 1 : WMFFeedNotificationMaxPerDay;
    [self.feedContentSource loadContentForDate:self.date
                        inManagedObjectContext:self.dataStore.viewContext
                                         force:YES
                                    completion:^{
                                        XCTAssertEqual([defaults wmf_inTheNewsMostRecentDateNotificationCount], count);
                                        [expectation fulfill];
                                    }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];
}

- (void)testDoesntIncrementNotificationCountForSameArticles {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:1];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];
    NSInteger count = self.isScheduledForTomorrow ? 1 : 2;
    [self.feedContentSource loadContentForDate:self.date
                        inManagedObjectContext:self.dataStore.viewContext
                                         force:YES
                                    completion:^{
                                        XCTAssertEqual([defaults wmf_inTheNewsMostRecentDateNotificationCount], count);
                                        [expectation fulfill];
                                    }];

    [self waitForExpectationsWithTimeout:10
                                 handler:^(NSError *_Nullable error) {
                                     if (error) {
                                         XCTFail();
                                     }
                                 }];

    expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                        inManagedObjectContext:self.dataStore.viewContext
                                         force:YES
                                    completion:^{
                                        XCTAssertEqual([defaults wmf_inTheNewsMostRecentDateNotificationCount], count);
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
    stubRequest(@"GET", self.feedURL.absoluteString).andReturn(200).withHeaders(@{@"Content-Type": @"application/json"}).withBody(feedJSONData); // News item isn't in top read - test skip notify

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:WMFFeedNotificationMaxPerDay - 1];

    NSInteger count = WMFFeedNotificationMaxPerDay - 1;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];

    [self.feedContentSource loadContentForDate:self.date
                        inManagedObjectContext:self.dataStore.viewContext
                                         force:YES
                                    completion:^{
                                        XCTAssertEqual([defaults wmf_inTheNewsMostRecentDateNotificationCount], count);
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults wmf_setInTheNewsNotificationsEnabled:YES];
    [defaults wmf_setMostRecentInTheNewsNotificationDate:self.date];
    [defaults wmf_setInTheNewsMostRecentDateNotificationCount:WMFFeedNotificationMaxPerDay];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for content to load"];
    NSInteger count = self.isScheduledForTomorrow ? 1 : WMFFeedNotificationMaxPerDay;
    [self.feedContentSource loadContentForDate:self.date
                        inManagedObjectContext:self.dataStore.viewContext
                                         force:YES
                                    completion:^{
                                        XCTAssertEqual([defaults wmf_inTheNewsMostRecentDateNotificationCount], count);
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
