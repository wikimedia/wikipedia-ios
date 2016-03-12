//
//  WMFSearchPagesDataSourceTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/13/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import XCTest;
#import <Quick/Quick.h>
@import Nimble;
@import NSDate_Extensions;

#import "MWKHistoryEntry+MWKRandom.h"
#import "WMFRecentPagesDataSource.h"
#import "MWKDataStore+TempDataStoreForEach.h"
#import "NSDateFormatter+WMFExtensions.h"

@interface MWKHistoryList (SectionDataSourceTesting)

- (NSArray<MWKTitle*>*)injectWithStubbedEntriesFromDate:(NSDate*)date;

@end

QuickSpecBegin(WMFRecentPagesDataSourceTests)

__block MWKHistoryList * historyList;
__block WMFRecentPagesDataSource* recentPagesDataSource;

configureTempDataStoreForEach(tempDataStore, ^{
    MWKUserDataStore* userDataStore = tempDataStore.userDataStore;
    historyList = userDataStore.historyList;
    recentPagesDataSource = [[WMFRecentPagesDataSource alloc] initWithRecentPagesList:historyList];
});

describe(@"partitioning by date", ^{
    context(@"history contains items from today", ^{
        NSDate* today = [NSDate date];
        NSDate* yesterday = [today dateBySubtractingDays:1];
        NSDate* lastWeek = [today dateBySubtractingDays:7];

        __block NSArray<MWKTitle*>* todaysTitles;

        beforeEach(^{
            todaysTitles = [historyList injectWithStubbedEntriesFromDate:today];
        });

        describe(@"first section", ^{
            it(@"should have items from today", ^{
                NSArray<MWKTitle*>* firstSectionTitles =
                    [[SSBaseDataSource indexPathArrayWithRange:NSMakeRange(0, todaysTitles.count) inSection:0]
                     bk_map:^MWKTitle*(NSIndexPath* indexPath) {
                    return [recentPagesDataSource titleForIndexPath:indexPath];
                }];
                expect(firstSectionTitles).to(equal(todaysTitles));
            });

            it(@"should have a 'TODAY' header", ^{
                expect([recentPagesDataSource titleForHeaderInSection:0]).to(contain(@"TODAY"));
            });
        });

        context(@"history also contains items from yesterday", ^{
            __block NSArray<MWKTitle*>* yesterdaysTitles;

            beforeEach(^{
                yesterdaysTitles = [historyList injectWithStubbedEntriesFromDate:yesterday];
            });

            describe(@"yesterday section", ^{
                it(@"should have items from yesterday", ^{
                    NSArray<MWKTitle*>* secondSectionTitles =
                        [[SSBaseDataSource indexPathArrayWithRange:NSMakeRange(0, yesterdaysTitles.count) inSection:1]
                         bk_map:^MWKTitle*(NSIndexPath* indexPath) {
                        return [recentPagesDataSource titleForIndexPath:indexPath];
                    }];
                    expect(secondSectionTitles).to(equal(yesterdaysTitles));
                });

                it(@"should have a 'YESTERDAY' header", ^{
                    expect([recentPagesDataSource titleForHeaderInSection:1]).to(contain(@"YESTERDAY"));
                });
            });

            context(@"history also contains items from last week", ^{
                __block NSArray<MWKTitle*>* lastWeeksTitles;
                beforeEach(^{
                    lastWeeksTitles = [historyList injectWithStubbedEntriesFromDate:lastWeek];
                });

                it(@"should have a single section with all entries from last week", ^{
                    NSArray<MWKTitle*>* thirdSectionTitles =
                        [[SSBaseDataSource indexPathArrayWithRange:NSMakeRange(0, yesterdaysTitles.count) inSection:2]
                         bk_map:^MWKTitle*(NSIndexPath* indexPath) {
                        return [recentPagesDataSource titleForIndexPath:indexPath];
                    }];
                    expect(thirdSectionTitles).to(equal(lastWeeksTitles));
                });

                it(@"should have a header with last week's formatted day", ^{
                    expect([recentPagesDataSource titleForHeaderInSection:2])
                    .to(contain([[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:lastWeek]));
                });
            });
        });
    });
});

QuickSpecEnd

@implementation MWKHistoryList (SectionDataSourceTesting)

- (NSArray<MWKTitle*>*)injectWithStubbedEntriesFromDate:(NSDate*)date {
    MWKHistoryEntry* entryFromDate = [MWKHistoryEntry random];
    entryFromDate.date = [date dateAtStartOfDay];

    MWKHistoryEntry* entryFromLaterThatDay = [MWKHistoryEntry random];
    entryFromLaterThatDay.date = [NSDate dateWithTimeInterval:10 sinceDate:entryFromDate.date];

    [self addEntry:entryFromDate];
    [self addEntry:entryFromLaterThatDay];

    NSArray<MWKTitle*>* orderedTitlesFromDate = [self.entries wmf_mapAndRejectNil:^id _Nullable (MWKHistoryEntry* _Nonnull obj) {
        return [obj.date isEqualToDateIgnoringTime:date] ? obj.title : nil;
    }];

    return orderedTitlesFromDate;
}

@end
