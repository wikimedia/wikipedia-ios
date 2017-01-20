#import "WMFArticle+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest;

@property (nonatomic) BOOL isExcludedFromFeed;
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
@property (nullable, nonatomic, copy) NSString *thumbnailURLString;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nullable, nonatomic, retain) NSDictionary *pageViews;
@property (nullable, nonatomic, retain) NSNumber *signedQuadKey;

@end

NS_ASSUME_NONNULL_END
