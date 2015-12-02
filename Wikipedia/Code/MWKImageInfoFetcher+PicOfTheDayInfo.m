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

static NSString* const MWKPOTDImageInfoErrorDomain = @"MWKPOTDImageInfoErrorDomain";

typedef NS_ENUM(NSInteger, MWKPOTDImageInfoErrorCode) {
    MWKPOTDImageInfoErrorCodeEmptyInfo
};

@interface NSError (MWKPOTDImageInfoErrorDomain)

+ (instancetype)wmf_emptyPOTDErrorForDate:(NSDate*)date;

@end

typedef id(^MWKImageInfoResolve)(NSArray<MWKImageInfo*>*);

static MWKImageInfoResolve MWKImageInfoHandleEmptyInfoForDate(NSDate* date) {
    return ^id(NSArray<MWKImageInfo*>* infoObjects) {
        if (infoObjects.count < 1) {
            return [NSError wmf_emptyPOTDErrorForDate:date];
        } else {
            return infoObjects;
        }
    };
}

@implementation MWKImageInfoFetcher (PicOfTheDayInfo)

- (AnyPromise*)fetchPicOfTheDaySectionInfoForDate:(NSDate*)date
                                 metadataLanguage:(nullable NSString*)metadataLanguage {
    return [self fetchPartialInfoForImagesOnPages:@[[date wmf_picOfTheDayPageTitle]]
                                         fromSite:[MWKSite wikimediaCommons]
                                 metadataLanguage:metadataLanguage]
    .then(MWKImageInfoHandleEmptyInfoForDate(date));
}

- (AnyPromise*)fetchPicOfTheDayGalleryInfoForDate:(NSDate*)date
                                 metadataLanguage:(nullable NSString*)metadataLanguage {
    return [self fetchGalleryInfoForImagesOnPages:@[[date wmf_picOfTheDayPageTitle]]
                                         fromSite:[MWKSite wikimediaCommons]
                                 metadataLanguage:metadataLanguage]
           .then(MWKImageInfoHandleEmptyInfoForDate(date));
}


@end

@implementation NSError (MWKPOTDImageInfoErrorDomain)

+ (instancetype)wmf_emptyPOTDErrorForDate:(NSDate*)date {
    return [[NSError alloc] initWithDomain:MWKPOTDImageInfoErrorDomain
                                      code:MWKPOTDImageInfoErrorCodeEmptyInfo
                                  userInfo:@{
                NSLocalizedDescriptionKey:
                [MWLocalizedString(@"potd-empty-error-description", nil)
                 stringByReplacingOccurrencesOfString:@"$1"
                                           withString:[date descriptionWithLocale:[NSLocale currentLocale]]]
            }];
}

@end

NS_ASSUME_NONNULL_END
