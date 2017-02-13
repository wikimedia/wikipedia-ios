#import "WMFArticle+CoreDataClass.h"

typedef NS_ENUM(NSUInteger, WMFGeoType) {
    WMFGeoTypeUnknown = 0,
    WMFGeoTypeCountry,
    WMFGeoTypeSatellite,
    WMFGeoTypeAdm1st,
    WMFGeoTypeAdm2nd,
    WMFGeoTypeAdm3rd,
    WMFGeoTypeCity,
    WMFGeoTypeAirport,
    WMFGeoTypeMountain,
    WMFGeoTypeIsle,
    WMFGeoTypeWaterBody,
    WMFGeoTypeForest,
    WMFGeoTypeRiver,
    WMFGeoTypeGlacier,
    WMFGeoTypeEvent,
    WMFGeoTypeEdu,
    WMFGeoTypePass,
    WMFGeoTypeRailwayStation,
    WMFGeoTypeLandmark
};

typedef NS_ENUM(NSUInteger, WMFArticleAction) {
    WMFArticleActionNone = 0,
    WMFArticleActionRead,
    WMFArticleActionSave,
    WMFArticleActionShare,
};

@interface WMFArticle (WMFExtensions)

@property (nonatomic, readonly, nullable) NSURL *URL;

@property (nonatomic, nullable) NSURL *thumbnailURL;

@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *pageViewsSortedByDate;

@property (nonatomic, readonly) WMFGeoType geoType;

@property (nonatomic, readonly) int64_t geoDimension;

- (void)updateViewedDateWithoutTime; // call after setting viewedDate

@end
