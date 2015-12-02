//
//  WMFModalPOTDGalleryDataSource.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/1/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalPOTDGalleryDataSource.h"
#import "MWKImageInfo.h"
#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "NSDate+WMFPOTDDateRange.h"
#import "NSProcessInfo+WMFOperatingSystemVersionChecks.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFModalPOTDGalleryDataSource ()

@property (nonatomic, strong) NSDictionary<NSDate*, MWKImageInfo*>* homeInfo;

@property (nonatomic, strong) NSMutableDictionary<NSDate*, MWKImageInfo*>* galleryInfo;

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@end

@implementation WMFModalPOTDGalleryDataSource
@synthesize delegate;

- (instancetype)initWithTodaysInfo:(MWKImageInfo*)info {
    /*
     TODO: when we allow selection of arbitrary dates in the feed, the date range needs to either be passed
     in the initializer (pulled from home section schema items) or calculated from the arbitrary date (see
     wmf_datesUntilToday).
    */
    NSArray<NSDate*>* dates = [[[NSDate date] dateBySubtractingDays:15] wmf_datesUntilToday];

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        dates = [dates wmf_reverseArrayIfApplicationIsRTL];
    }

    self = [super initWithItems:dates];
    if (self) {
        self.homeInfo = [NSMutableDictionary dictionaryWithObject:info forKey:dates.firstObject];
        self.galleryInfo = [NSMutableDictionary new];
    }

    return self;
}

- (MWKImageInfoFetcher*)fetcher {
    if (!_fetcher) {
        _fetcher = [[MWKImageInfoFetcher alloc] init];
    }
    return _fetcher;
}

- (NSDate*)dateAtIndexPath:(NSIndexPath*)indexPath {
    return [self itemAtIndexPath:indexPath];
}

- (NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
    return [self.homeInfo[[self dateAtIndexPath:indexPath]] imageThumbURL];
}

- (nullable MWKImageInfo*)imageInfoAtIndexPath:(NSIndexPath*)indexPath {
    return self.galleryInfo[[self dateAtIndexPath:indexPath]];
}

- (void)fetchDataAtIndexPath:(NSIndexPath*)indexPath {
    @weakify(self);
    NSDate* date = [self dateAtIndexPath:indexPath];
    [self.fetcher fetchPicOfTheDayGalleryInfoForDate:date
                                     metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]
    .then(^(NSArray<MWKImageInfo*>* infoObjects) {
        @strongify(self);
        MWKImageInfo* info = infoObjects.firstObject;
        NSParameterAssert(info);
        NSIndexPath* updatedIndexPath = [self indexPathForItem:date];
        NSParameterAssert(updatedIndexPath);
        self.galleryInfo[date] = info;
        [self.delegate modalGalleryDataSource:self
                        updatedItemsAtIndexes:[NSIndexSet indexSetWithIndex:updatedIndexPath.item]];
    })
    .catch(^(NSError* error) {
        @strongify(self);
        [self.delegate modalGalleryDataSource:self didFailWithError:error];
    });
}

@end

NS_ASSUME_NONNULL_END
