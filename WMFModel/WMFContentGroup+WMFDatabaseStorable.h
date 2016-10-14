#import "WMFContentGroup.h"
#import "WMFDatabaseStorable.h"
@import CoreLocation;

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

+ (NSURL *)urlForSiteURL:(NSURL *)url;

- (NSURL *)url;

@end

@interface WMFRelatedPagesContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForArticleURL:(NSURL *)url;

- (NSURL *)url;

@end

@interface WMFLocationContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForLocation:(CLLocation *)location;

- (NSURL *)url;

@end

@interface WMFPictureOfTheDayContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

@interface WMFRandomContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

@interface WMFFeaturedArticleContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end

@interface WMFTopReadContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date;

- (NSURL *)url;

@end
