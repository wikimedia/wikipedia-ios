@import XCTest;
#import <Quick/Quick.h>
@import Nimble;
@import NSDate_Extensions;

#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import "MWKDataStore+TempDataStoreForEach.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "MWKDataStore+WMFDataSources.h"
#import "WMFAsyncTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"

@interface MWKHistoryList (WMFDataSourceTesting)

- (MWKHistoryEntry *)addEntry:(MWKHistoryEntry *)entry;

@end

@interface MWKHistoryList (SectionDataSourceTesting)

- (NSArray<MWKHistoryEntry *> *)injectWithStubbedEntriesFromDate:(NSDate *)date;

@end

@implementation MWKHistoryList (SectionDataSourceTesting)

- (NSArray<MWKHistoryEntry *> *)injectWithStubbedEntriesFromDate:(NSDate *)date {
    MWKHistoryEntry *entryFromDate = [MWKHistoryEntry random];
    entryFromDate.dateViewed = [date dateAtStartOfDay];

    MWKHistoryEntry *entryFromLaterThatDay = [MWKHistoryEntry random];
    entryFromLaterThatDay.dateViewed = [NSDate dateWithTimeInterval:10 sinceDate:entryFromDate.dateViewed];

    [self addEntry:entryFromDate];
    [self addEntry:entryFromLaterThatDay];

    return @[entryFromLaterThatDay, entryFromDate];
}

@end

@interface MWKHistoryDataSourceTests : XCTestCase

@property (nonatomic, strong) MWKDataStore *dataStore;
@property (nonatomic, strong) MWKHistoryList *historyList;
@property (nonatomic, strong) id<WMFDataSource> recentPagesDataSource;

@property (nonatomic, strong) NSArray<MWKHistoryEntry *> *todaysTitles;
@property (nonatomic, strong) NSArray<MWKHistoryEntry *> *yesterdaysTitles;
@property (nonatomic, strong) NSArray<MWKHistoryEntry *> *lastWeeksTitles;

@end

@implementation MWKHistoryDataSourceTests

- (void)setUp {
    [super setUp];

    self.dataStore = [MWKDataStore temporaryDataStore];
    self.historyList = [[MWKHistoryList alloc] initWithDataStore:self.dataStore];
    NSAssert([self.historyList numberOfItems] == 0, @"History list must be empty before tests begin.");
    self.recentPagesDataSource = [self.dataStore historyGroupedByDateDataSource];
    NSAssert([self.recentPagesDataSource numberOfItems] == 0, @"History datasource must be empty before tests begin.");

    NSDate *today = [NSDate date];
    NSDate *yesterday = [today dateBySubtractingDays:1];
    NSDate *lastWeek = [today dateBySubtractingDays:7];

    self.todaysTitles = [self.historyList injectWithStubbedEntriesFromDate:today];
    self.yesterdaysTitles = [self.historyList injectWithStubbedEntriesFromDate:yesterday];
    self.lastWeeksTitles = [self.historyList injectWithStubbedEntriesFromDate:lastWeek];
}

- (void)tearDown {
    [self.dataStore removeFolderAtBasePath];
    [super tearDown];
}

- (void)testToday {
    NSDate *today = [NSDate date];

    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        MWKHistoryEntry *entry = (MWKHistoryEntry *)[self.recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        expect([entry.dateViewed dateAtStartOfDay]).to(equal([today dateAtStartOfDay]));
        for (int i = 0; i < [self.recentPagesDataSource numberOfItemsInSection:0]; i++) {
            MWKHistoryEntry *entry = (MWKHistoryEntry *)[self.recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            expect(entry).to(equal(self.todaysTitles[i]));
        }
        NSString *title = [self.recentPagesDataSource titleForSectionIndex:0];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[title doubleValue]];
        expect([date dateAtStartOfDay]).to(equal([today dateAtStartOfDay]));

        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testYesterday {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    NSDate *today = [NSDate date];
    NSDate *yesterday = [today dateBySubtractingDays:1];

    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        MWKHistoryEntry *entry = (MWKHistoryEntry *)[self.recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        expect([entry.dateViewed dateAtStartOfDay]).to(equal([yesterday dateAtStartOfDay]));

        for (int i = 0; i < [self.recentPagesDataSource numberOfItemsInSection:1]; i++) {
            MWKHistoryEntry *entry = (MWKHistoryEntry *)[self.recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
            expect(entry).to(equal(self.yesterdaysTitles[i]));
        }

        NSString *title = [self.recentPagesDataSource titleForSectionIndex:1];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[title doubleValue]];
        expect([date dateAtStartOfDay]).to(equal([yesterday dateAtStartOfDay]));

        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

- (void)testLastWeek {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Should resolve"];

    NSDate *today = [NSDate date];
    NSDate *lastWeek = [today dateBySubtractingDays:7];

    dispatchOnMainQueueAfterDelayInSeconds(3.0, ^{
        MWKHistoryEntry *entry = (MWKHistoryEntry *)[self.recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        expect([entry.dateViewed dateAtStartOfDay]).to(equal([lastWeek dateAtStartOfDay]));

        for (int i = 0; i < [self.recentPagesDataSource numberOfItemsInSection:2]; i++) {
            MWKHistoryEntry *entry = (MWKHistoryEntry *)[self.recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:2]];
            expect(entry).to(equal(self.lastWeeksTitles[i]));
        }

        NSString *title = [self.recentPagesDataSource titleForSectionIndex:2];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[title doubleValue]];
        expect([date dateAtStartOfDay]).to(equal([lastWeek dateAtStartOfDay]));

        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:WMFDefaultExpectationTimeout handler:NULL];
}

@end
