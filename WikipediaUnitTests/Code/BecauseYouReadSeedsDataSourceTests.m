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

@property (nonatomic, strong) MWKHistoryEntry *fooEntry;
@property (nonatomic, strong) MWKHistoryEntry *sfEntry;
@property (nonatomic, strong) MWKHistoryEntry *laEntry;

@property (nonatomic, strong) WMFRelatedSectionBlackList *blackList;

@property (nonatomic, strong) id<WMFDataSource> becauseYouReadSeedsDataSource;

@end

@implementation BecauseYouReadSeedsDataSourceTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)setUp {
    [super setUp];

    NSURL *fooURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Foo"];
    NSURL *sfURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"San Francisco"];
    NSURL *laURL = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"Los Angeles"];

    self.dataStore = [MWKDataStore temporaryDataStore];

    self.historyList = [[MWKHistoryList alloc] initWithDataStore:self.dataStore];

    self.fooEntry = [self.historyList addPageToHistoryWithURL:fooURL];
    self.sfEntry = [self.historyList addPageToHistoryWithURL:sfURL];
    self.laEntry = [self.historyList addPageToHistoryWithURL:laURL];

    self.blackList = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self.dataStore];

    self.becauseYouReadSeedsDataSource = [self.dataStore becauseYouReadSeedsDataSource];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSignificantlyViewedItemsFromHistoryListAppearInBecauseYouReadSeedsDataSource {
    // We should see 'foo', 'la' and 'sf' in seeds. They were significantly viewed and not blacklisted

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfEntry.url];

    @weakify(self);
    [self.dataStore notifyWhenWriteTransactionsComplete:^{
        @strongify(self);
        NSArray *expectedItems = @[self.fooEntry, self.laEntry, self.sfEntry];
        XCTAssertEqualObjects([self itemsFromDataSource:self.becauseYouReadSeedsDataSource], expectedItems);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (void)testNotSignificantlyViewedItemsFromHistoryListDoNotAppearInBecauseYouReadSeedsDataSource {
    // We should see only 'foo' in seeds - it was only significantly viewed item

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];
    @weakify(self);
    [self.dataStore notifyWhenWriteTransactionsComplete:^{
        @strongify(self);
        NSArray *expectedItems = @[self.fooEntry];
        XCTAssertEqualObjects([self itemsFromDataSource:self.becauseYouReadSeedsDataSource], expectedItems);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (void)testBlacklistedItemDoesNotAppearInBecauseYouReadSeedsDataSource {
    // We should see 'foo' and 'la' in seeds, but not 'sf', which was blacklisted even though it was significantly viewed

    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laEntry.url];

    [self.blackList addBlackListArticleURL:self.sfEntry.url];

    @weakify(self);
    [self.dataStore notifyWhenWriteTransactionsComplete:^{
        @strongify(self);
        NSArray *expectedItems = @[self.fooEntry, self.laEntry];
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
        [items addObject:entry];
    }
    return items;
}

#pragma clang diagnostic pop

@end
