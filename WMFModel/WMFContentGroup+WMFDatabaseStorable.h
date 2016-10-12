
#import "WMFContentGroup.h"
#import "WMFDatabaseStorable.h"
@import CoreLocation;

@interface WMFContentGroup (WMFDatabaseStorable)<WMFDatabaseStorable>

@end


@interface WMFContinueReadingContentGroup (WMFDatabaseStorable)

+ (NSURL *)url;

@end


@interface WMFMainPageContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL*)url;

@end

@interface WMFRelatedPagesContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForArticleURL:(NSURL*)url;

@end

@interface WMFLocationContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForLocation:(CLLocation*)location;

@end

@interface WMFPictureOfTheDayContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL*)url date:(NSDate*)date;

@end

@interface WMFRandomContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL*)url date:(NSDate*)date;

@end

@interface WMFFeaturedArticleContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL*)url date:(NSDate*)date;

@end

@interface WMFTopReadContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL*)url date:(NSDate*)date;

@end
