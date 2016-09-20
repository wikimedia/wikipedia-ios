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

@interface BecauseYouReadSeedsDataSourceTests : XCTestCase <WMFDataSourceDelegate>

@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) MWKHistoryList* historyList;

@property (nonatomic, strong) MWKHistoryEntry* fooEntry;
@property (nonatomic, strong) MWKHistoryEntry* sfEntry;
@property (nonatomic, strong) MWKHistoryEntry* laEntry;

@property (nonatomic, strong) WMFRelatedSectionBlackList* blackList;

@property (nonatomic, strong) id<WMFDataSource> becauseYouReadSeedsDataSource;

@property (nonatomic, copy) void (^testBlock)(id<WMFDataSource>);

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
    self.becauseYouReadSeedsDataSource.delegate = self;
}

- (void)tearDown {
    [super tearDown];
}

- (void)dataSourceDidUpdateAllData:(id<WMFDataSource>)dataSource {
    // Yap calls this method a lot - once (or more!) for each item we add to the data source.
    // So expectation fulfilment was put into testBlock, so we could define these blocks in
    // test methods.
    if(self.testBlock){
        self.testBlock(dataSource);
    }
}

- (void)testSignificantlyViewedItemsFromHistoryListAppearInBecauseYouReadSeedsDataSource {
    // We should see 'foo', 'la' and 'sf' in seeds. They were significantly viewed and not blacklisted
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.laEntry.url];
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.sfEntry.url];
    
    @weakify(self);
    self.testBlock = ^(id<WMFDataSource> dataSource){
        @strongify(self);
        if([dataSource numberOfItems] == 3){
            NSArray *expectedItems = @[self.fooEntry, self.laEntry, self.sfEntry];
            XCTAssertEqualObjects([self itemsFromDataSource:dataSource], expectedItems);
            self.testBlock = nil;
            [expectation fulfill];
        }
    };

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (void)testNotSignificantlyViewedItemsFromHistoryListDoNotAppearInBecauseYouReadSeedsDataSource {
    // We should see only 'foo' in seeds - it was only significantly viewed item
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];
    
    [self.historyList setSignificantlyViewedOnPageInHistoryWithURL:self.fooEntry.url];

    @weakify(self);
    self.testBlock = ^(id<WMFDataSource> dataSource){
        @strongify(self);
        if([dataSource numberOfItems] == 1){
            NSArray *expectedItems = @[self.fooEntry];
            XCTAssertEqualObjects([self itemsFromDataSource:dataSource], expectedItems);
            self.testBlock = nil;
            [expectation fulfill];
        }
    };
    
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
    self.testBlock = ^(id<WMFDataSource> dataSource){
        @strongify(self);
        if([dataSource numberOfItems] == 2){
            NSArray *expectedItems = @[self.fooEntry, self.laEntry];
            XCTAssertEqualObjects([self itemsFromDataSource:dataSource], expectedItems);
            self.testBlock = nil;
            [expectation fulfill];
        }
    };
    
    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout
                                 handler:nil];
}

- (NSArray*)itemsFromDataSource:(id<WMFDataSource>)dataSource {
    NSMutableArray* items = [[NSMutableArray alloc] init];
    for (int i = 0; i < [dataSource numberOfItemsInSection:0]; i++) {
        MWKHistoryEntry *entry = [dataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [items addObject:entry];
    }
    return items;
}

#pragma clang diagnostic pop

@end
