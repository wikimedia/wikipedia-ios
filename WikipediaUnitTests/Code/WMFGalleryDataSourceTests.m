//
//  WMFGalleryDataSourceTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/8/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;
#import <SSDataSources/SSDataSources.h>

#import "WMFModalPOTDGalleryDataSource.h"
#import "WMFArticleImageGalleryDataSource.h"
#import "WMFModalArticleImageGalleryDataSource.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"

#import "SSArrayDataSource+WMFReverseIfRTL.h"
#import "MWKDataStore+TempDataStoreForEach.h"
#import "NSDate+WMFDateRanges.h"
#import "NSDate+Utilities.h"

QuickConfigurationBegin(WMFGalleryDataSourceTestsConfiguration)

+ (void)configure : (Configuration*)configuration {
    sharedExamples(@"an RTL compliant gallery data source", ^(QCKDSLSharedExampleContext contextProvider) {
        __block NSArray* rawItems;
        __block SSBaseDataSource* dataSource;
        beforeEach(^{
            NSDictionary* context = contextProvider();
            rawItems = context[@"items"];
            dataSource = context[@"dataSource"];
        });

        it(@"should reorder the items if necessary", ^{
            [[rawItems wmf_reverseArrayIfApplicationIsRTL]
             enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                expect([dataSource itemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]])
                .toWithDescription(equal(obj), [NSString stringWithFormat:@"Expected item at index %lu to be %@", idx, obj]);
            }];
        });
    });
}

QuickConfigurationEnd

QuickSpecBegin(WMFGalleryDataSourceTests)

describe(@"SSArrayDataSource.wmf_initWithitemsAndReverseIfNeeded", ^{
    itBehavesLike(@"an RTL compliant gallery data source", ^{
        NSArray* items = @[@0, @1, @2];
        return @{
            @"items": items,
            @"dataSource": [[SSArrayDataSource alloc] wmf_initWithItemsAndReverseIfNeeded:items]
        };
    });
});

describe(@"WMFArticleImageGalleryDataSource", ^{
    __block MWKArticle* article;
    configureTempDataStoreForEach(tempDataStore, ^{
        NSDictionary* fixtureJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"];
        article = [[MWKArticle alloc] initWithTitle:[MWKTitle random]
                                          dataStore:tempDataStore
                                               dict:fixtureJSON];
    });

    itBehavesLike(@"an RTL compliant gallery data source", ^{
        return @{ @"items": article.images.uniqueLargestVariants,
                  @"dataSource": [[WMFArticleImageGalleryDataSource alloc] initWithArticle:article] };
    });

    // test the subclass too, same context
    itBehavesLike(@"an RTL compliant gallery data source", ^{
        return @{ @"items": article.images.uniqueLargestVariants,
                  @"dataSource": [[WMFModalArticleImageGalleryDataSource alloc] initWithArticle:article] };
    });
});

describe(@"WMFModalPOTDImageGalleryDataSource", ^{
    itBehavesLike(@"an RTL compliant gallery data source", ^{
        NSDate* testDate = [NSDate date];
        NSArray<NSDate*>* dates = [[testDate dateBySubtractingDays:WMFDefaultNumberOfPOTDDates] wmf_datesUntilDate:testDate];
        MWKImageInfo* info = [[MWKImageInfo alloc] initWithCanonicalPageTitle:@"Foo"
                                                             canonicalFileURL:[NSURL URLWithString:@"http://foo.org/bar"]
                                                             imageDescription:nil
                                                                      license:nil
                                                                  filePageURL:nil
                                                                imageThumbURL:nil
                                                                        owner:nil
                                                                    imageSize:CGSizeZero
                                                                    thumbSize:CGSizeZero];
        return @{ @"items": dates,
                  @"dataSource": [[WMFModalPOTDGalleryDataSource alloc] initWithInfo:info forDate:testDate] };
    });
});

QuickSpecEnd
