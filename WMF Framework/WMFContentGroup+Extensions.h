#import "WMFContentGroup+CoreDataClass.h"

@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int16_t, WMFContentType) {
    WMFContentTypeUnknown = 0,
    WMFContentTypeURL = 1,
    WMFContentTypeImage = 2,
    WMFContentTypeTopReadPreview = 3,
    WMFContentTypeStory = 4,
    WMFContentTypeAnnouncement = 5
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
    WMFContentGroupKindLocationPlaceholder = 12
};

@interface WMFContentGroup (Extensions)

+ (nullable NSString *)databaseKeyForURL:(nullable NSURL *)URL;

@property (nonatomic, assign) WMFContentType contentType;

@property (nonatomic, assign) WMFContentGroupKind contentGroupKind;

@property (nonatomic, strong, nullable) NSURL *URL;
@property (nonatomic, strong, nullable) NSURL *articleURL;
@property (nonatomic, strong, nullable) NSURL *siteURL;

- (void)updateKey; //Sets key property based on content group kind
- (void)updateContentType;
- (void)updateDailySortPriority;

+ (nullable NSURL *)mainPageURLForSiteURL:(NSURL *)URL;
+ (nullable NSURL *)continueReadingContentGroupURL;
+ (nullable NSURL *)relatedPagesContentGroupURLForArticleURL:(NSURL *)articleURL;
+ (nullable NSURL *)articleURLForRelatedPagesContentGroupURL:(nullable NSURL *)url;
+ (nullable NSURL *)announcementURLForSiteURL:(NSURL *)siteURL identifier:(NSString *)identifier;
+ (nullable NSURL *)randomContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate;
+ (nullable NSURL *)locationContentGroupURLForLocation:(CLLocation *)location;
+ (nullable NSURL *)locationPlaceholderContentGroupURL;

- (BOOL)isForLocalDate:(NSDate *)date;           //date is a date in the user's time zone
@property (nonatomic, readonly) BOOL isForToday; //is for today in the user's time zone

- (void)updateVisibility;
- (void)markDismissed;


@end

@interface NSManagedObjectContext (WMFContentGroup)

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent;

- (nullable WMFContentGroup *)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable NSArray<NSCoding> *)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock;

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind;

- (void)removeContentGroup:(WMFContentGroup *)group;

- (void)removeContentGroupsWithKeys:(NSArray<NSString *> *)keys;

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind;

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)url;

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)key ascending:(BOOL)ascending withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block;

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind;

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date;

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date siteURL:(NSURL *)url;

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date;

- (nullable WMFContentGroup *)locationContentGroupWithinMeters:(CLLocationDistance)meters ofLocation:(CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
