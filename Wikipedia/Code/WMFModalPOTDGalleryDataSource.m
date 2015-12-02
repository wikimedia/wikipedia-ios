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

NS_ASSUME_NONNULL_BEGIN

@interface WMFModalPOTDGalleryDataSource ()

@property (nonatomic, strong) NSDictionary<NSDate*, MWKImageInfo*>* homeInfo;

@property (nonatomic, strong) NSMutableDictionary<NSDate*, MWKImageInfo*>* galleryInfo;

@property (nonatomic, strong) MWKImageInfoFetcher* fetcher;

@end

@implementation WMFModalPOTDGalleryDataSource
@synthesize delegate;

- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(NSDate*)date {
    self = [super initWithItems:@[date]];
    if (self) {
        self.homeInfo = [NSMutableDictionary dictionaryWithObject:info forKey:date];
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
    NSArray<NSDate*>* fetchedDates = [self allItems];
    @weakify(self);
    [self.fetcher fetchPicOfTheDayGalleryInfoForDates:fetchedDates
                                     metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]
    .then(^(NSArray<MWKImageInfo*>* infoObjects) {
        @strongify(self);
        NSParameterAssert(infoObjects.count == fetchedDates.count);
        [infoObjects enumerateObjectsUsingBlock:^(MWKImageInfo * _Nonnull info, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDate* date = fetchedDates[idx];
            self.galleryInfo[date] = info;
        }];
        NSIndexSet* updatedIndexes = [[self allItems] indexesOfObjectsWithOptions:0
                                                                      passingTest:^BOOL(id  _Nonnull obj,
                                                                                        NSUInteger __unused idx,
                                                                                        BOOL * _Nonnull _) {
            return [fetchedDates containsObject:obj];
        }];
        [self.delegate modalGalleryDataSource:self updatedItemsAtIndexes:updatedIndexes];
    });
}

@end

NS_ASSUME_NONNULL_END
