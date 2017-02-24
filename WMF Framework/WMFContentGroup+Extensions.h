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
+ (nullable NSURL *)announcementURLForSiteURL:(NSURL *)siteURL identifier:(NSString *)identifier;
+ (nullable NSURL *)randomContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate;
+ (nullable NSURL *)locationContentGroupURLForLocation:(CLLocation *)location;
+ (nullable NSURL *)locationPlaceholderContentGroupURL;

- (BOOL)isForLocalDate:(NSDate *)date;           //date is a date in the user's time zone
@property (nonatomic, readonly) BOOL isForToday; //is for today in the user's time zone

- (void)updateVisibility;
- (void)markDismissed;

@end

NS_ASSUME_NONNULL_END
