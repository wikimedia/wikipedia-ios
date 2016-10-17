#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "NSDate+Utilities.h"
#import "NSDateFormatter+WMFExtensions.h"

@implementation WMFContentGroup (WMFDatabaseStorable)

+ (NSURL *)baseUrl {
    NSURL *url = [NSURL URLWithString:@"wikipedia://content/"];
    return url;
}

+ (NSString *)databaseKeyForURL:(NSURL *)url {
    NSParameterAssert(url);
    return [url absoluteString];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] baseUrl]];
}

+ (NSString *)databaseCollectionName {
    return NSStringFromClass([WMFContentGroup class]);
}
@end

@implementation WMFContinueReadingContentGroup (WMFDatabaseStorable)

+ (NSURL *)url {
    return [[self baseUrl] URLByAppendingPathComponent:@"continue-reading"];
}

- (NSURL *)url {
    return [[self class] url];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] url]];
}

@end

@implementation WMFMainPageContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url {
    NSURL *theURL = [[self baseUrl] URLByAppendingPathComponent:@"main-page"];
    theURL = [theURL URLByAppendingPathComponent:url.wmf_domain];
    theURL = [theURL URLByAppendingPathComponent:url.wmf_language];
    return theURL;
}

- (NSURL *)url {
    return [[self class] urlForSiteURL:self.siteURL];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForSiteURL:self.siteURL]];
}

@end

@implementation WMFRelatedPagesContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForArticleURL:(NSURL *)url {
    NSURL *theURL = [[self baseUrl] URLByAppendingPathComponent:@"related-pages"];
    theURL = [theURL URLByAppendingPathComponent:url.wmf_domain];
    theURL = [theURL URLByAppendingPathComponent:url.wmf_language];
    theURL = [theURL URLByAppendingPathComponent:url.wmf_title];
    return theURL;
}

- (NSURL *)url {
    return [[self class] urlForArticleURL:self.articleURL];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForArticleURL:self.articleURL]];
}

@end

@implementation WMFLocationContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForLocation:(CLLocation *)location {
    NSURL *url = [[self baseUrl] URLByAppendingPathComponent:@"nearby"];
    url = [url URLByAppendingPathComponent:[location description]];
    return url;
}

- (NSURL *)url {
    return [[self class] urlForLocation:self.location];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForLocation:self.location]];
}

@end

@implementation WMFPictureOfTheDayContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date {
    NSURL *urlKey = [[self baseUrl] URLByAppendingPathComponent:@"picture-of-the-day"];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_domain];
    urlKey = [urlKey URLByAppendingPathComponent:[[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:date]];
    return urlKey;
}

- (NSURL *)url {
    return [[self class] urlForSiteURL:self.siteURL date:self.date];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForSiteURL:self.siteURL date:self.date]];
}

@end

@implementation WMFRandomContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date {
    NSURL *urlKey = [[self baseUrl] URLByAppendingPathComponent:@"random"];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_domain];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_language];
    urlKey = [urlKey URLByAppendingPathComponent:[[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:date]];
    return urlKey;
}

- (NSURL *)url {
    return [[self class] urlForSiteURL:self.siteURL date:self.date];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForSiteURL:self.siteURL date:self.date]];
}

@end

@implementation WMFFeaturedArticleContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date {
    NSURL *urlKey = [[self baseUrl] URLByAppendingPathComponent:@"featured-article"];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_domain];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_language];
    urlKey = [urlKey URLByAppendingPathComponent:[[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:date]];
    return urlKey;
}

- (NSURL *)url {
    return [[self class] urlForSiteURL:self.siteURL date:self.date];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForSiteURL:self.siteURL date:self.date]];
}

@end

@implementation WMFTopReadContentGroup (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL *)url date:(NSDate *)date {
    NSURL *urlKey = [[self baseUrl] URLByAppendingPathComponent:@"top-read"];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_domain];
    urlKey = [urlKey URLByAppendingPathComponent:url.wmf_language];
    urlKey = [urlKey URLByAppendingPathComponent:[[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:date]];
    return urlKey;
}

- (NSURL *)url {
    return [[self class] urlForSiteURL:self.siteURL date:self.date];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:[[self class] urlForSiteURL:self.siteURL date:self.date]];
}

@end
