#import <Mantle/Mantle.h>
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFContentType) {
    WMFContentTypeURL,
    WMFContentTypeImage,
    WMFContentTypeTopReadPreview,
    WMFContentTypeStory
};

@interface WMFContentGroup : MTLModel

/**
 *  The kind of content group.
 */
+ (NSString *)kind;

/**
 *  The type of content that the group contains
 *  When fetching the content from the data store, you will recieve an array of this type.
 */
@property (nonatomic, assign, readonly) WMFContentType contentType;

/**
 *  The date associated with the content group.
 */
@property (nonatomic, strong, readonly) NSDate *date;

- (instancetype)init;

- (instancetype)initWithDate:(NSDate *)date NS_DESIGNATED_INITIALIZER;

- (NSInteger)dailySortPriority;

/**
 *  Determine ordering between two content groups.
 *
 *  Use this to sort home content groups. Sort currently works like this:
 *  Continue reading is always at the top if present.
 *  The rest of the content groups are sorted by their date descending
 *  If featured, main page, random, and nearby are from the "same day", then special sorting takes precendence:
 *  They are always in the order of featured, main page, random, nearby.
 *
 */
- (NSComparisonResult)compare:(WMFContentGroup *)contentGroup;

@end

@interface WMFSiteContentGroup : WMFContentGroup

/**
 *  The site associated with the content group.
 */
@property (nonatomic, strong, readonly) NSURL *siteURL;

- (instancetype)initWithSiteURL:(NSURL *)url;

- (instancetype)initWithDate:(NSDate *)date siteURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDate:(NSDate *)date NS_UNAVAILABLE;

@end

@interface WMFContinueReadingContentGroup : WMFContentGroup

@end

@interface WMFMainPageContentGroup : WMFSiteContentGroup

@end

@interface WMFRelatedPagesContentGroup : WMFSiteContentGroup

/**
 *  The url of the article to fetch related titles for.
 */
@property (nonatomic, strong, readonly) NSURL *articleURL;

- (instancetype)initWithArticleURL:(NSURL *)url date:(NSDate *)date;

@end

@interface WMFLocationContentGroup : WMFSiteContentGroup

/**
 *  The location fetch nearby articles for.
 */
@property (nonatomic, strong, readonly) CLLocation *location;

/**
 *  The placemark cooresponding to the content group above.
 */
@property (nonatomic, strong, readonly) CLPlacemark *placemark;

- (instancetype)initWithLocation:(CLLocation *)location placemark:(nullable CLPlacemark *)placemark siteURL:(NSURL *)url;

@end

@interface WMFPictureOfTheDayContentGroup : WMFSiteContentGroup

@end

@interface WMFRandomContentGroup : WMFSiteContentGroup

@end

@interface WMFFeaturedArticleContentGroup : WMFSiteContentGroup

@end

@interface WMFTopReadContentGroup : WMFSiteContentGroup

/**
 *  The date for which the most read articles were fetched. Usually yesterday
 */
@property (nonatomic, strong, readonly) NSDate *mostReadDate;

- (instancetype)initWithDate:(NSDate *)date mostReadDate:(NSDate *)mostReadDate siteURL:(NSURL *)url;

- (instancetype)initWithDate:(NSDate *)date siteURL:(NSURL *)url NS_UNAVAILABLE;

@end

@interface WMFNewsContentGroup : WMFSiteContentGroup

@end

NS_ASSUME_NONNULL_END
