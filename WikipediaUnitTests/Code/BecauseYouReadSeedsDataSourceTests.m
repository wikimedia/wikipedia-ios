#import <Quick/Quick.h>
@import Nimble;

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

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface BecauseYouReadSeedsDataSourceTests : XCTestCase

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKHistoryList* historyList;

@property (nonatomic, strong) MWKHistoryEntry* fooEntry;
@property (nonatomic, strong) MWKHistoryEntry* sfEntry;
@property (nonatomic, strong) MWKHistoryEntry* laEntry;

@property (nonatomic, strong) WMFRelatedSectionBlackList* blackList;

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
}

- (void)tearDown {
    [super tearDown];
}

- (NSArray*)itemsFromDataSource:(id<WMFDataSource>)dataSource {
    NSMutableArray* items = [[NSMutableArray alloc] init];
    for (int i = 0; i < [dataSource numberOfItemsInSection:0]; i++) {
        MWKHistoryEntry *entry = [dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [items addObject:entry];
    }
    return items;
}

- (void)testSignificantlyViewedItemsFromHistoryListAppearInBecauseYouReadSeedsDataSource {
    
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfEntry.url];
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"We should see 'foo', 'la' and 'sf' in seeds. They were significantly viewed and not blacklisted"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        NSArray* items = [self itemsFromDataSource:[self.dataStore becauseYouReadSeedsDataSource]];
        expect(items).to(equal(@[self.fooEntry, self.laEntry, self.sfEntry]));
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testNotSignificantlyViewedItemsFromHistoryListDoNotAppearInBecauseYouReadSeedsDataSource {
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"We should see nothing in seeds. None of the items were significantly viewed"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        NSArray* items = [self itemsFromDataSource:[self.dataStore becauseYouReadSeedsDataSource]];
        expect(items).to(equal(@[]));
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testBlacklistedItemDoesNotAppearInBecauseYouReadSeedsDataSource {
    
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laEntry.url];

    [self.blackList addBlackListArticleURL:self.sfEntry.url];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"We should see 'foo' and 'la' in seeds, but not 'sf', which was blacklisted even though it was significantly viewed"];
    
    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        NSArray* items = [self itemsFromDataSource:[self.dataStore becauseYouReadSeedsDataSource]];
        expect(items).to(equal(@[self.fooEntry, self.laEntry]));
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

#pragma clang diagnostic pop

@end
