
@import XCTest;
#import <Quick/Quick.h>
@import Nimble;
#import <NSDate-Extensions/NSDate+Utilities.h>

#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKDataStore+TempDataStoreForEach.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "MWKDataStore+WMFDataSources.h"

@interface MWKHistoryList (WMFDataSourceTesting)

- (MWKHistoryEntry*)addEntry:(MWKHistoryEntry*)entry;

@end


@interface MWKHistoryList (SectionDataSourceTesting)

- (NSArray<NSURL*>*)injectWithStubbedEntriesFromDate:(NSDate*)date;

@end

QuickSpecBegin(WMFRecentPagesDataSourceTests)

__block MWKHistoryList * historyList;
__block id<WMFDataSource> recentPagesDataSource;

configureTempDataStoreForEach(tempDataStore, ^{
    MWKUserDataStore* userDataStore = tempDataStore.userDataStore;
    historyList = userDataStore.historyList;
    recentPagesDataSource = [tempDataStore historyDataSource];
});

describe(@"partitioning by date", ^{
    context(@"history contains items from today", ^{
        NSDate* today = [NSDate date];
        NSDate* yesterday = [today dateBySubtractingDays:1];
        NSDate* lastWeek = [today dateBySubtractingDays:7];

        __block NSArray<NSURL*>* todaysTitles;

        beforeEach(^{
            todaysTitles = [historyList injectWithStubbedEntriesFromDate:today];
        });

        describe(@"first section", ^{
            it(@"should have items from today", ^{
                MWKHistoryEntry* entry = [recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                expect([entry.dateViewed dateAtStartOfDay]).to(equal([today dateAtStartOfDay]));
                
                for (int i = 0; i < [recentPagesDataSource numberOfItemsInSection:0]; i++){
                    MWKHistoryEntry* entry = [recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                    expect(entry.url).to(equal(todaysTitles[i]));
                }
            });

            it(@"First section header should be today", ^{
                NSString* title = [recentPagesDataSource titleForSectionIndex:0];
                NSDate* date = [NSDate dateWithTimeIntervalSince1970:[title doubleValue]];
                expect([date dateAtStartOfDay]).to(equal([today dateAtStartOfDay]));
            });
        });

        context(@"history also contains items from yesterday", ^{
            __block NSArray<NSURL*>* yesterdaysTitles;

            beforeEach(^{
                yesterdaysTitles = [historyList injectWithStubbedEntriesFromDate:yesterday];
            });

            describe(@"yesterday section", ^{
                it(@"should have items from yesterday", ^{
                    MWKHistoryEntry* entry = [recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    expect([entry.dateViewed dateAtStartOfDay]).to(equal([yesterday dateAtStartOfDay]));

                    for (int i = 0; i < [recentPagesDataSource numberOfItemsInSection:0]; i++){
                        MWKHistoryEntry* entry = [recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                        expect(entry.url).to(equal(yesterdaysTitles[i]));
                    }
                });

                it(@"First section header should be yesterday", ^{
                    NSString* title = [recentPagesDataSource titleForSectionIndex:0];
                    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[title doubleValue]];
                    expect([date dateAtStartOfDay]).to(equal([yesterday dateAtStartOfDay]));
                });
            });

            context(@"history also contains items from last week", ^{
                __block NSArray<NSURL*>* lastWeeksTitles;
                beforeEach(^{
                    lastWeeksTitles = [historyList injectWithStubbedEntriesFromDate:lastWeek];
                });

                it(@"should have a single section with all entries from last week", ^{
                    MWKHistoryEntry* entry = [recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    expect([entry.dateViewed dateAtStartOfDay]).to(equal([lastWeek dateAtStartOfDay]));

                    for (int i = 0; i < [recentPagesDataSource numberOfItemsInSection:0]; i++){
                        MWKHistoryEntry* entry = [recentPagesDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                        expect(entry.url).to(equal(lastWeeksTitles[i]));
                    }
                });

                it(@"should have a header with last week's date", ^{
                    NSString* title = [recentPagesDataSource titleForSectionIndex:0];
                    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[title doubleValue]];
                    expect([date dateAtStartOfDay]).to(equal([lastWeek dateAtStartOfDay]));
                });
            });
        });
    });
});

QuickSpecEnd

@implementation MWKHistoryList (SectionDataSourceTesting)

- (NSArray<NSURL*>*)injectWithStubbedEntriesFromDate:(NSDate*)date {
    MWKHistoryEntry* entryFromDate = [MWKHistoryEntry random];
    entryFromDate.dateViewed = [date dateAtStartOfDay];

    MWKHistoryEntry* entryFromLaterThatDay = [MWKHistoryEntry random];
    entryFromLaterThatDay.dateViewed = [NSDate dateWithTimeInterval:10 sinceDate:entryFromDate.dateViewed];

    [self addEntry:entryFromDate];
    [self addEntry:entryFromLaterThatDay];

    return @[entryFromLaterThatDay, entryFromDate];
}

@end
