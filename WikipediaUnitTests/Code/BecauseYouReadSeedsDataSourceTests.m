#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSavedPageList.h"
#import "MWKSavedPageEntry.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "WMFAsyncTestCase.h"
#import "MWKDataStore+WMFDataSources.h"
#import "WMFDatabaseDataSource.h"
#import "MWKHistoryList.h"
#import "Wikipedia-Swift.h"
#import "WMFRelatedSectionBlackList.h"
#import "YapDatabaseConnection+WMFExtensions.h"
#import "YapDatabaseViewOptions.h"

@interface BecauseYouReadSeedsDataSourceTests : XCTestCase

@property (nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong) MWKHistoryList *historyList;

@property (nonatomic, strong) NSURL *fooURL;
@property (nonatomic, strong) NSURL *sfURL;
@property (nonatomic, strong) NSURL *laURL;

@property (nonatomic, strong) WMFRelatedSectionBlackList *blackList;

@property (nonatomic, strong) id<WMFDataSource> becauseYouReadSeedsDataSource;

@end

@implementation BecauseYouReadSeedsDataSourceTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)setUp {
    [super setUp];

    self.fooURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"];
    self.sfURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"San Francisco"];
    self.laURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Los Angeles"];

    self.dataStore = [MWKDataStore temporaryDataStore];

    self.historyList = [[MWKHistoryList alloc] initWithDataStore:self.dataStore];

    [self.historyList addPageToHistoryWithURL:self.fooURL];
    [self.historyList addPageToHistoryWithURL:self.sfURL];
    [self.historyList addPageToHistoryWithURL:self.laURL];

    self.blackList = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self.dataStore];

    self.becauseYouReadSeedsDataSource = [self.dataStore becauseYouReadSeedsDataSource];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSignificantlyViewedItemsFromHistoryListAppearInBecauseYouReadSeedsDataSource {
    // We should see 'foo', 'la' and 'sf' in seeds. They were significantly viewed and not blacklisted

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooURL];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laURL];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfURL];

    @weakify(self);
    [self.dataStore notifyWhenWriteTransactionsComplete:^{
        @strongify(self);
        NSArray *expectedItems = @[self.fooURL.wmf_databaseKey, self.laURL.wmf_databaseKey, self.sfURL.wmf_databaseKey];

        XCTAssertEqualObjects([self itemsFromDataSource:self.becauseYouReadSeedsDataSource], expectedItems);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (void)testNotSignificantlyViewedItemsFromHistoryListDoNotAppearInBecauseYouReadSeedsDataSource {
    // We should see only 'foo' in seeds - it was only significantly viewed item

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooURL];
    @weakify(self);
    [self.dataStore notifyWhenWriteTransactionsComplete:^{
        @strongify(self);
        NSArray *expectedItems = @[self.fooURL.wmf_databaseKey];
        XCTAssertEqualObjects([self itemsFromDataSource:self.becauseYouReadSeedsDataSource], expectedItems);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (void)testBlacklistedItemDoesNotAppearInBecauseYouReadSeedsDataSource {
    // We should see 'foo' and 'la' in seeds, but not 'sf', which was blacklisted even though it was significantly viewed

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooURL];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfURL];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laURL];

    [self.blackList addBlackListArticleURL:self.sfURL];

    @weakify(self);
    [self.dataStore notifyWhenWriteTransactionsComplete:^{
        @strongify(self);
        NSArray *expectedItems = @[self.fooURL.wmf_databaseKey, self.laURL.wmf_databaseKey];
        XCTAssertEqualObjects([self itemsFromDataSource:self.becauseYouReadSeedsDataSource], expectedItems);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (NSArray *)itemsFromDataSource:(id<WMFDataSource>)dataSource {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (int i = 0; i < [dataSource numberOfItemsInSection:0]; i++) {
        MWKHistoryEntry *entry = (MWKHistoryEntry *)[dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [items addObject:entry.url.wmf_databaseKey];
    }
    return items;
}

#pragma clang diagnostic pop

@end
