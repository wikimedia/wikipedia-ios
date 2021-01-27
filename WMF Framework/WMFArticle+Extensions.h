#import <WMF/WMFArticle+CoreDataClass.h>

@class MWKSearchResult;
@class WMFFeedArticlePreview;

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

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticle (WMFExtensions)

@property (nonatomic, readonly, nullable) NSURL *URL;

@property (nonatomic, copy, nonnull) NSString *displayTitleHTML;

@property (nonatomic, readonly, nullable) NSString *capitalizedWikidataDescription;

@property (nonatomic, nullable) NSURL *thumbnailURL; // Deprecated. Use imageURLForWidth:

+ (nullable NSURL *)imageURLForTargetImageWidth:(NSInteger)width fromImageSource:(NSString *)imageSource withOriginalWidth:(NSInteger)originalWidth;
- (nullable NSURL *)imageURLForWidth:(NSInteger)width;

@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *pageViewsSortedByDate;

@property (nonatomic, readonly) WMFGeoType geoType;

@property (nonatomic, readonly) int64_t geoDimension;

- (void)updateViewedDateWithoutTime; // call after setting viewedDate

- (void)updateWithSearchResult:(nullable MWKSearchResult *)searchResult;

@end

@interface NSManagedObjectContext (WMFArticle)

- (nullable WMFArticle *)fetchArticleWithURL:(nullable NSURL *)articleURL;

- (nullable WMFArticle *)fetchArticleWithKey:(nullable NSString *)key variant:(nullable NSString *)variant;

- (nullable NSArray<WMFArticle *> *)fetchArticlesWithKey:(nullable NSString *)key variant:(nullable NSString *)variant error:(NSError **)error;
- (nullable NSArray<WMFArticle *> *)fetchArticlesWithKey:(nullable NSString *)key error:(NSError **)error; // Temporary shim for ArticleSummary that is not yet variant-aware

- (nullable WMFArticle *)createArticleWithKey:(nullable NSString *)key variant:(nullable NSString *)variant;
- (nullable WMFArticle *)createArticleWithKey:(nullable NSString *)key; // Temporary shim for ArticleSummary that is not yet variant-aware

- (nullable WMFArticle *)fetchOrCreateArticleWithKey:(nullable NSString *)key variant:(nullable NSString *)variant;

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL;

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL updatedWithSearchResult:(nullable MWKSearchResult *)searchResult;

- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(nullable NSURL *)articleURL updatedWithFeedPreview:(nullable WMFFeedArticlePreview *)feedPreview pageViews:(nullable NSDictionary<NSDate *, NSNumber *> *)pageViews;

- (nullable WMFArticle *)fetchArticleWithWikidataID:(nullable NSString *)wikidataID;

@end

// WMFDataSource maintains a temporary local NSCache of WMFArticle instances.
// The database key is derived from the article URL which does not take language variants into account.
// Instances of this class are used as the key in that cache
@interface WMFArticleTemporaryCacheKey: NSObject
-(instancetype) initWithDatabaseKey:(NSString *)databaseKey variant:(nullable NSString *)variant;
-(instancetype) init NS_UNAVAILABLE;
@property (readonly, nonatomic, copy) NSString *databaseKey;
@property (readonly, nonatomic, copy) NSString *variant;
@end

NS_ASSUME_NONNULL_END
