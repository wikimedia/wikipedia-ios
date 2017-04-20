#import "WMFArticle+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest;

@property (nonatomic) BOOL isExcludedFromFeed;
@property (nonatomic) BOOL isDownloaded;
@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSDate *viewedDate;
@property (nullable, nonatomic, copy) NSDate *viewedDateWithoutTime;
@property (nullable, nonatomic, copy) NSString *viewedFragment;
@property (nonatomic) double viewedScrollPosition;
@property (nullable, nonatomic, copy) NSDate *newsNotificationDate;
@property (nullable, nonatomic, copy) NSDate *savedDate;
@property (nonatomic) BOOL wasSignificantlyViewed;
@property (nullable, nonatomic, copy) NSString *displayTitle;
@property (nullable, nonatomic, copy) NSString *wikidataDescription;
@property (nullable, nonatomic, copy) NSString *snippet;
@property (nullable, nonatomic, copy) NSString *thumbnailURLString; // deprecated
@property (nullable, nonatomic, copy) NSString *imageURLString; // original image URL
@property (nullable, nonatomic, copy) NSNumber *imageWidth;
@property (nullable, nonatomic, copy) NSNumber *imageHeight;
@property (nullable, nonatomic, copy) NSDictionary *pageViews;
@property (nullable, nonatomic, copy) NSNumber *signedQuadKey;
@property (nullable, nonatomic, copy) NSNumber *geoDimensionNumber;
@property (nullable, nonatomic, copy) NSNumber *geoTypeNumber;
@property (nullable, nonatomic, copy) NSNumber *placesSortOrder;

@property (nonatomic) double latitude; //__deprecated; // Use coordinate instead (not using actual __deprecated tag due to inability to ignore the warning when these are used in Swift)
@property (nonatomic) double longitude; //__deprecated; // Use coordinate instead (not using actual __deprecated tag due to inability to ignore the warning when these are used in Swift)

@end

NS_ASSUME_NONNULL_END
