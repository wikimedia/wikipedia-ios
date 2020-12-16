#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "NSDate+WMFPOTDTitle.h"
@import WMF;

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
            [[NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"potd-description-prefix", nil, nil, @"Picture of the day for %1$@", @"Prefix to picture of the day description which states it was the picture of the day for a specific date. The %1$@ token is subtituted for the date."), dateString] mutableCopy];
        if (info.imageDescription.length) {
            [potdDescription appendString:@"\n\n"];
            [potdDescription appendString:info.imageDescription];
        }
        return [[MWKImageInfo alloc] initWithCanonicalPageTitle:info.canonicalPageTitle
                                               canonicalFileURL:info.canonicalFileURL
                                               imageDescription:potdDescription
                                          imageDescriptionIsRTL:info.imageDescriptionIsRTL
                                                        license:info.license
                                                    filePageURL:info.filePageURL
                                                  imageThumbURL:info.imageThumbURL
                                                          owner:info.owner
                                                      imageSize:info.imageSize
                                                      thumbSize:info.thumbSize];
    };
}

@implementation MWKImageInfoFetcher (PicOfTheDayInfo)

- (void)fetchPicOfTheDayGalleryInfoForDate:(NSDate *)date
                          metadataLanguage:(nullable NSString *)metadataLanguage
                                   failure:(WMFErrorHandler)failure
                                   success:(WMFSuccessIdHandler)success {
    [self fetchGalleryInfoForImagesOnPages:@[[date wmf_picOfTheDayPageTitle]]
                               fromSiteURL:[NSURL wmf_wikimediaCommonsURL]
                          metadataLanguage:metadataLanguage
                                   failure:failure
                                   success:^(id _Nonnull object) {
                                       if ([selectFirstImageInfo(date)(object) isKindOfClass:[NSError class]]) {
                                           failure(selectFirstImageInfo(date)(object));
                                       } else {
                                           success(addPictureOfTheDayToDescriptionForDate(date)(selectFirstImageInfo(date)(object)));
                                       }
                                   }];
}

@end

@implementation NSError (MWKPOTDImageInfoErrorDomain)

+ (instancetype)wmf_emptyPOTDErrorForDate:(NSDate *)date {
    return [[NSError alloc] initWithDomain:MWKPOTDImageInfoErrorDomain
                                      code:MWKPOTDImageInfoErrorCodeEmptyInfo
                                  userInfo:@{
                                      NSLocalizedDescriptionKey:
                                          [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"potd-empty-error-description", nil, nil, @"Failed to retrieve picture of the day for %1$@", @"Error message when app fails to download Commons Picture of the Day. %1$@ will be substitued with the date which the app attempted to retrieve."), [[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date]]
                                  }];
}

@end

NS_ASSUME_NONNULL_END
