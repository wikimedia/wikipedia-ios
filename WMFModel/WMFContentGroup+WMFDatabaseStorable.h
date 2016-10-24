#import "WMFContentGroup.h"
#import "WMFDatabaseStorable.h"
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup (WMFDatabaseStorable) <WMFDatabaseStorable>

/*
 * Base URL for all content groups
 * wikipedia://content/
 */
+ (NSURL *)baseUrl;

@end

@interface WMFContinueReadingContentGroup (WMFDatabaseStorable)

+ (NSURL *)url;

- (NSURL *)url;

@end

@interface WMFMainPageContentGroup (WMFDatabaseStorable)

+ (nullable NSURL *)urlForSiteURL:(NSURL *)url;

- (NSURL *)url;

@end

@interface WMFRelatedPagesContentGroup (WMFDatabaseStorable)

+ (nullable NSURL *)urlForArticleURL:(NSURL *)url;

- (NSURL *)url;

@end

@interface WMFLocationContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForLocation:(CLLocation *)location;

- (NSURL *)url;

@end

@interface WMFPictureOfTheDayContentGroup (WMFDatabaseStorable)

+ (nullable NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

@interface WMFRandomContentGroup (WMFDatabaseStorable)

+ (nullable NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

@interface WMFFeaturedArticleContentGroup (WMFDatabaseStorable)

+ (nullable NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

@interface WMFTopReadContentGroup (WMFDatabaseStorable)

+ (nullable NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

NS_ASSUME_NONNULL_END
