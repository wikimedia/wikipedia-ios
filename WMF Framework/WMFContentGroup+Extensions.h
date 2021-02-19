#import <WMF/WMFContentGroup+CoreDataClass.h>

@import CoreLocation;

@class WMFInMemoryURLKey;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int16_t, WMFContentType) {
    WMFContentTypeUnknown = 0,
    WMFContentTypeURL = 1,
    WMFContentTypeImage = 2,
    WMFContentTypeTopReadPreview = 3,
    WMFContentTypeStory = 4,
    WMFContentTypeAnnouncement = 5,
    WMFContentTypeOnThisDayEvent = 6,
    WMFContentTypeNotification = 7,
    WMFContentTypeTheme = 8,
    WMFContentTypeReadingList = 9
};

typedef NS_ENUM(int32_t, WMFContentGroupKind) {
    WMFContentGroupKindUnknown = 0,
    WMFContentGroupKindContinueReading = 1,
    WMFContentGroupKindMainPage = 2,
    WMFContentGroupKindRelatedPages = 3,
    WMFContentGroupKindLocation = 4,
    WMFContentGroupKindPictureOfTheDay = 5,
    WMFContentGroupKindRandom = 6,
    WMFContentGroupKindFeaturedArticle = 7,
    WMFContentGroupKindTopRead = 8,
    WMFContentGroupKindNews = 9,
    WMFContentGroupKindNotification = 10,
    WMFContentGroupKindAnnouncement = 11,
    WMFContentGroupKindLocationPlaceholder = 12,
    WMFContentGroupKindOnThisDay = 13,
    WMFContentGroupKindTheme = 14,
    WMFContentGroupKindReadingList = 15
};

typedef NS_ENUM(int16_t, WMFContentGroupUndoType) {
    WMFContentGroupUndoTypeNone = 0,
    WMFContentGroupUndoTypeContentGroupKind = 1,
    WMFContentGroupUndoTypeContentGroup = 2
};

@interface WMFContentGroup (Extensions)

+ (nullable NSString *)databaseKeyForURL:(nullable NSURL *)URL;

@property (nonatomic, assign) WMFContentType contentType;

@property (nonatomic, assign) WMFContentGroupKind contentGroupKind;

@property (nonatomic, assign) WMFContentGroupUndoType undoType;

@property (nonatomic, strong, nullable) NSURL *URL;
@property (nonatomic, strong, nullable) NSURL *articleURL;
@property (nonatomic, strong, nullable) NSURL *siteURL;

@property (nonatomic, readonly, nullable) WMFInMemoryURLKey *inMemoryKey;

- (void)updateKey; //Sets key property based on content group kind
- (void)updateContentType;
- (void)updateDailySortPriorityWithSortOrderByContentLanguageCode:(nullable NSDictionary<NSString *, NSNumber *> *)sortOrderByContentLanguageCode;

+ (nullable NSURL *)mainPageURLForSiteURL:(NSURL *)URL;
+ (nullable NSURL *)continueReadingContentGroupURLForArticleURL:(NSURL *)articleURL;
+ (nullable NSURL *)relatedPagesContentGroupURLForArticleURL:(NSURL *)articleURL;
+ (nullable NSURL *)articleURLForRelatedPagesContentGroupURL:(nullable NSURL *)url;
+ (nullable NSURL *)announcementURLForSiteURL:(NSURL *)siteURL identifier:(NSString *)identifier;
+ (nullable NSURL *)randomContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate;
+ (nullable NSURL *)onThisDayContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate;
+ (nullable NSURL *)locationContentGroupURLForLocation:(CLLocation *)location languageVariantCode:(NSString *)languageVariantCode;
+ (nullable NSURL *)locationPlaceholderContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode;
+ (nullable NSURL *)notificationContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode;
+ (nullable NSURL *)themeContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode;
+ (nullable NSURL *)readingListContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode;

- (BOOL)isForLocalDate:(NSDate *)date;           //date is a date in the user's time zone
@property (nonatomic, readonly) BOOL isForToday; //is for today in the user's time zone
@property (nonatomic, readonly) BOOL isRTL; //content is in an RTL language

// Utilizes featuredContentIdentifier for storage so can't be set along with featuredContentIdentifier
@property (nonatomic) NSInteger featuredContentIndex;

- (void)setFullContentObject:(id<NSCoding>)fullContentObject; // will automatically create or update fullContent relationship
- (void)updateContentPreviewWithContent:(id)content;

- (void)updateVisibilityForUserIsLoggedIn:(BOOL)isLoggedIn;
- (void)markDismissed;

@end

@interface NSManagedObjectContext (WMFContentGroup)

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent;

- (nullable WMFContentGroup *)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind;

- (void)removeContentGroup:(WMFContentGroup *)group;

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind;

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url;

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)key ascending:(BOOL)ascending withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind;

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind forSiteURL:(nullable NSURL *)siteURL;

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind withPredicate:(nullable NSPredicate *)predicate;

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind;

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind forSiteURL:(nullable NSURL *)siteURL;

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date;

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date siteURL:(NSURL *)siteURL;

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date;

- (nullable NSArray<WMFContentGroup *> *)orderedGroupsOfKind:(WMFContentGroupKind)kind withPredicate:(nullable NSPredicate *)predicate;

- (nullable WMFContentGroup *)locationContentGroupWithSiteURL:(nullable NSURL *)siteURL withinMeters:(CLLocationDistance)meters ofLocation:(CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
