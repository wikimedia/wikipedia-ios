//
//  MWKImageInfoFetcher+PicOfTheDayInfo.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "NSDate+WMFPOTDTitle.h"
#import "MWKSite+CommonsSite.h"
#import "MWKImageInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MWKImageInfoFetcher (PicOfTheDayInfo)

- (AnyPromise*)fetchPicOfTheDaySectionInfoForDate:(NSDate*)date
                                 metadataLanguage:(nullable NSString*)metadataLanguage {
    return [self fetchPartialInfoForImagesOnPages:@[[date wmf_picOfTheDayPageTitle]]
                                         fromSite:[MWKSite wikimediaCommons]
                                 metadataLanguage:metadataLanguage];
}

- (AnyPromise*)fetchPicOfTheDayGalleryInfoForDates:(NSArray<NSDate*>*)dates
                                  metadataLanguage:(nullable NSString*)metadataLanguage {
    NSArray<NSString*>* potdTitles = [dates bk_map:^NSString*(NSDate* date) {
        return [date wmf_picOfTheDayPageTitle];
    }];
    return [self fetchPartialInfoForImagesOnPages:potdTitles
                                         fromSite:[MWKSite wikimediaCommons]
                                 metadataLanguage:metadataLanguage];
}

@end

NS_ASSUME_NONNULL_END
