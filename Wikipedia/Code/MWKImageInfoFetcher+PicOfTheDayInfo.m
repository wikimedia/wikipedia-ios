//
//  MWKImageInfoFetcher+PicOfTheDayInfo.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/2/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "NSDate+WMFPOTDTitle.h"
#import "MWKImageInfo.h"
#import "NSDateFormatter+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const MWKPOTDImageInfoErrorDomain = @"MWKPOTDImageInfoErrorDomain";

typedef NS_ENUM(NSInteger, MWKPOTDImageInfoErrorCode) {
    MWKPOTDImageInfoErrorCodeEmptyInfo
};

@interface NSError (MWKPOTDImageInfoErrorDomain)

+ (instancetype)wmf_emptyPOTDErrorForDate:(NSDate *)date;

@end

typedef id (^MWKImageInfoResolve)(id _Nullable);

static MWKImageInfoResolve selectFirstImageInfo(NSDate *date) {
    return ^id(NSArray<MWKImageInfo *> *infoObjects) {
      if (infoObjects.count < 1) {
          return [NSError wmf_emptyPOTDErrorForDate:date];
      } else {
          return infoObjects.firstObject;
      }
    };
}

static MWKImageInfoResolve addPictureOfTheDayToDescriptionForDate(NSDate *date) {
    return ^id(MWKImageInfo *info) {
      NSString *dateString = [[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date];
      NSMutableString *potdDescription =
          [[MWLocalizedString(@"potd-description-prefix", nil)
              stringByReplacingOccurrencesOfString:@"$1"
                                        withString:dateString] mutableCopy];
      if (info.imageDescription.length) {
          [potdDescription appendString:@"\n\n"];
          [potdDescription appendString:info.imageDescription];
      }
      return [[MWKImageInfo alloc] initWithCanonicalPageTitle:info.canonicalPageTitle
                                             canonicalFileURL:info.canonicalFileURL
                                             imageDescription:potdDescription
                                                      license:info.license
                                                  filePageURL:info.filePageURL
                                                imageThumbURL:info.imageThumbURL
                                                        owner:info.owner
                                                    imageSize:info.imageSize
                                                    thumbSize:info.thumbSize];
    };
}

@implementation MWKImageInfoFetcher (PicOfTheDayInfo)

- (AnyPromise *)fetchPicOfTheDaySectionInfoForDate:(NSDate *)date
                                  metadataLanguage:(nullable NSString *)metadataLanguage {
    return [self fetchPartialInfoForImagesOnPages:@[ [date wmf_picOfTheDayPageTitle] ]
                                      fromSiteURL:[NSURL wmf_wikimediaCommonsURL]
                                 metadataLanguage:metadataLanguage]
        .then(selectFirstImageInfo(date));
}

- (AnyPromise *)fetchPicOfTheDayGalleryInfoForDate:(NSDate *)date
                                  metadataLanguage:(nullable NSString *)metadataLanguage {
    return [self fetchGalleryInfoForImagesOnPages:@[ [date wmf_picOfTheDayPageTitle] ]
                                      fromSiteURL:[NSURL wmf_wikimediaCommonsURL]
                                 metadataLanguage:metadataLanguage]
        .then(selectFirstImageInfo(date))
        .then(addPictureOfTheDayToDescriptionForDate(date));
}

@end

@implementation NSError (MWKPOTDImageInfoErrorDomain)

+ (instancetype)wmf_emptyPOTDErrorForDate:(NSDate *)date {
    return [[NSError alloc] initWithDomain:MWKPOTDImageInfoErrorDomain
                                      code:MWKPOTDImageInfoErrorCodeEmptyInfo
                                  userInfo:@{
                                      NSLocalizedDescriptionKey :
                                          [MWLocalizedString(@"potd-empty-error-description", nil)
                                              stringByReplacingOccurrencesOfString:@"$1"
                                                                        withString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date]]
                                  }];
}

@end

NS_ASSUME_NONNULL_END
