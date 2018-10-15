#import "WMFArticle+CoreDataClass.h"

@class ReadingList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *displayTitle; // Don't use this property, use displayTitleHTML. It will set the plain text version to displayTitle.
@property (nullable, nonatomic, copy) NSString *displayTitleHTMLString; // Don't use this property, use displayTitleHTML
@property (nonatomic, copy) NSNumber *geoDimensionNumber;
@property (nonatomic, copy) NSNumber *geoTypeNumber;
@property (nonatomic, copy) NSNumber *imageHeight;
@property (nullable, nonatomic, copy) NSString *imageURLString; // original image URL
@property (nonatomic, copy) NSNumber *imageWidth;
@property (nonatomic) BOOL isDownloaded;
@property (nonatomic) BOOL isExcludedFromFeed;
@property (nullable, nonatomic, copy) NSString *key;
@property (nonatomic) double latitude;  //__deprecated; // Use coordinate instead (not using actual __deprecated tag due to inability to ignore the warning when these are used in Swift)
@property (nonatomic) double longitude; //__deprecated; // Use coordinate instead (not using actual __deprecated tag due to inability to ignore the warning when these are used in Swift)
@property (nullable, nonatomic, copy) NSDate *newsNotificationDate;
@property (nullable, nonatomic, retain) NSDictionary *pageViews;
@property (nullable, nonatomic, copy) NSNumber *placesSortOrder;
@property (nullable, nonatomic, copy) NSDate *savedDate;
@property (nullable, nonatomic, copy) NSNumber *signedQuadKey;
@property (nullable, nonatomic, copy) NSString *snippet;            // TODO: consider making naming consistent (probably use 'extract' instead of 'snippet' here and 'summary' elsewhere)
@property (nullable, nonatomic, copy) NSString *thumbnailURLString; // deprecated
@property (nullable, nonatomic, copy) NSDate *viewedDate;
@property (nullable, nonatomic, copy) NSDate *viewedDateWithoutTime;
@property (nullable, nonatomic, copy) NSString *viewedFragment;
@property (nonatomic) double viewedScrollPosition;
@property (nonatomic) BOOL wasSignificantlyViewed;
@property (nullable, nonatomic, copy) NSString *wikidataDescription;
@property (nullable, nonatomic, copy) NSString *wikidataID;
@property (nullable, nonatomic, retain) NSSet<ReadingList *> *readingLists;
@property (nullable, nonatomic, retain) NSSet<ReadingList *> *previewReadingLists;
@property (nullable, nonatomic, copy) NSNumber *errorCodeNumber;

@end

@interface WMFArticle (CoreDataGeneratedAccessors)

- (void)addReadingListsObject:(ReadingList *)value;
- (void)removeReadingListsObject:(ReadingList *)value;
- (void)addReadingLists:(NSSet<ReadingList *> *)values;
- (void)removeReadingLists:(NSSet<ReadingList *> *)values;

- (void)addPreviewReadingListsObject:(ReadingList *)value;
- (void)removePreviewReadingListsObject:(ReadingList *)value;
- (void)addPreviewReadingLists:(NSSet<ReadingList *> *)values;
- (void)removePreviewReadingLists:(NSSet<ReadingList *> *)values;

@end

NS_ASSUME_NONNULL_END
