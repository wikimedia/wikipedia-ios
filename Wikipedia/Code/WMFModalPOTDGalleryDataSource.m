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
#import "NSDate+WMFDateRanges.h"
#import "NSDate+Utilities.h"
#import "SSArrayDataSource+WMFReverseIfRTL.h"

NS_ASSUME_NONNULL_BEGIN

NSUInteger const WMFDefaultNumberOfPOTDDates = 15;

@interface WMFModalPOTDGalleryDataSource ()

@property (nonatomic, strong) NSDictionary<NSDate*, MWKImageInfo*>* homeInfo;

@property (nonatomic, strong) NSMutableDictionary<NSDate*, MWKImageInfo*>* galleryInfo;

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@end

@implementation WMFModalPOTDGalleryDataSource
@synthesize delegate;

- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(NSDate*)date {
    /*
       TODO: when we allow selection of arbitrary dates in the feed, the date range needs to either be passed
       in the initializer (pulled from home section schema items) or calculated from the arbitrary date (see
       wmf_datesUntilToday).
     */
    NSArray<NSDate*>* dates = [[date dateBySubtractingDays:WMFDefaultNumberOfPOTDDates] wmf_datesUntilDate:date];
    self = [self wmf_initWithItemsAndReverseIfNeeded:dates];
    if (self) {
        self.homeInfo    = [NSMutableDictionary dictionaryWithObject:info forKey:dates.firstObject];
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

- (nullable NSURL*)imageURLAtIndexPath:(NSIndexPath*)indexPath {
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
    .then(^(MWKImageInfo* info) {
        @strongify(self);
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
