#import "WMFContentGroup+Extensions.h"
#import "WMFAnnouncement.h"

@implementation WMFContentGroup (Extensions)

- (nullable NSURL *)URL {
    NSString *key = self.key;
    if (!key) {
        return nil;
    }
    return [NSURL URLWithString:key];
}

- (void)setURL:(NSURL *)URL {
    self.key = URL.absoluteString.precomposedStringWithCanonicalMapping;
}

+ (nullable NSString *)databaseKeyForURL:(nullable NSURL *)URL {
    NSParameterAssert(URL);
    return [[URL absoluteString] precomposedStringWithCanonicalMapping];
}

- (void)updateKey {
    NSURL *URL = nil;
    switch (self.contentGroupKind) {
        case WMFContentGroupKindUnknown:
            assert(false);
            break;
        case WMFContentGroupKindContinueReading:
            URL = [WMFContentGroup continueReadingContentGroupURL];
            break;
        case WMFContentGroupKindMainPage:
            URL = [WMFContentGroup mainPageURLForSiteURL:self.siteURL];
            break;
        case WMFContentGroupKindRelatedPages:
            URL = [WMFContentGroup relatedPagesContentGroupURLForArticleURL:self.articleURL];
            break;
        case WMFContentGroupKindLocation:
            URL = [WMFContentGroup locationContentGroupURLForLocation:self.location];
            break;
        case WMFContentGroupKindLocationPlaceholder:
            URL = [WMFContentGroup locationPlaceholderContentGroupURL];
            break;
        case WMFContentGroupKindPictureOfTheDay:
            URL = [WMFContentGroup pictureOfTheDayContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindRandom:
            URL = [WMFContentGroup randomContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindFeaturedArticle:
            URL = [WMFContentGroup featuredArticleContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindTopRead:
            URL = [WMFContentGroup topReadContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindNews:
            URL = [WMFContentGroup newsContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindNotification:
            URL = [WMFContentGroup notificationContentGroupURL];
            break;
        case WMFContentGroupKindAnnouncement:
            URL = [WMFContentGroup announcementURLForSiteURL:self.siteURL identifier:[(WMFAnnouncement *)self.content.firstObject identifier]];
        default:
            break;
    }
    assert(URL);
    self.key = [WMFContentGroup databaseKeyForURL:URL];
}

- (void)updateContentType {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindPictureOfTheDay:
            self.contentType = WMFContentTypeImage;
            break;
        case WMFContentGroupKindTopRead:
            self.contentType = WMFContentTypeTopReadPreview;
            break;
        case WMFContentGroupKindNews:
            self.contentType = WMFContentTypeStory;
            break;
        case WMFContentGroupKindUnknown:
            assert(false);
            self.contentType = WMFContentTypeUnknown;
            break;
        case WMFContentGroupKindAnnouncement:
            self.contentType = WMFContentTypeAnnouncement;
            break;
        case WMFContentGroupKindContinueReading:
        case WMFContentGroupKindMainPage:
        case WMFContentGroupKindRelatedPages:
        case WMFContentGroupKindLocation:
        case WMFContentGroupKindLocationPlaceholder:
        case WMFContentGroupKindRandom:
        case WMFContentGroupKindFeaturedArticle:
        case WMFContentGroupKindNotification:
        default:
            self.contentType = WMFContentTypeURL;
            break;
    }
}

- (void)updateDailySortPriority {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    switch (self.contentGroupKind) {
        case WMFContentGroupKindUnknown:
            break;
        case WMFContentGroupKindContinueReading:
            self.dailySortPriority = isPad ? 1 : 0;
            break;
        case WMFContentGroupKindMainPage:
            self.dailySortPriority = isPad ? 0 : 6;
            break;
        case WMFContentGroupKindRelatedPages:
            self.dailySortPriority = isPad ? 2 : 1;
            break;
        case WMFContentGroupKindLocation:
            self.dailySortPriority = 8;
            break;
        case WMFContentGroupKindLocationPlaceholder:
            self.dailySortPriority = 8;
            break;
        case WMFContentGroupKindPictureOfTheDay:
            self.dailySortPriority = isPad ? 6 : 5;
            break;
        case WMFContentGroupKindRandom:
            self.dailySortPriority = 7;
            break;
        case WMFContentGroupKindFeaturedArticle:
            self.dailySortPriority = isPad ? 3 : 2;
            break;
        case WMFContentGroupKindTopRead:
            self.dailySortPriority = isPad ? 4 : 3;
            break;
        case WMFContentGroupKindNews:
            self.dailySortPriority = isPad ? 5 : 4;
            break;
        case WMFContentGroupKindNotification:
            self.dailySortPriority = -1;
            break;
        case WMFContentGroupKindAnnouncement:
            self.dailySortPriority = -2;
            break;
        default:
            break;
    }
}

- (WMFContentType)contentType {
    return (WMFContentType)self.contentTypeInteger;
}

- (void)setContentType:(WMFContentType)contentType {
    self.contentTypeInteger = contentType;
}

- (WMFContentGroupKind)contentGroupKind {
    return (WMFContentGroupKind)self.contentGroupKindInteger;
}

- (void)setContentGroupKind:(WMFContentGroupKind)contentGroupKind {
    self.contentGroupKindInteger = contentGroupKind;
}

- (nullable NSURL *)articleURL {
    return [NSURL URLWithString:self.articleURLString];
}

- (void)setArticleURL:(nullable NSURL *)articleURL {
    self.articleURLString = articleURL.absoluteString;
}

- (nullable NSURL *)siteURL {
    return [NSURL URLWithString:self.siteURLString];
}

- (void)setSiteURL:(nullable NSURL *)siteURL {
    self.siteURLString = siteURL.absoluteString;
}

+ (NSURL *)baseURL {
    NSURL *URL = [NSURL URLWithString:@"wikipedia://content/"];
    return URL;
}

+ (nullable NSURL *)mainPageURLForSiteURL:(NSURL *)URL {
    NSString *language = URL.wmf_language;
    NSString *domain = URL.wmf_domain;
    NSParameterAssert(domain);
    NSParameterAssert(language);
    if (!domain || !language) {
        return nil;
    }

    NSURL *theURL = [[self baseURL] URLByAppendingPathComponent:@"main-page"];
    theURL = [theURL URLByAppendingPathComponent:domain];
    theURL = [theURL URLByAppendingPathComponent:language];
    return theURL;
}

+ (nullable NSURL *)continueReadingContentGroupURL {
    return [[self baseURL] URLByAppendingPathComponent:@"continue-reading"];
}

+ (nullable NSURL *)relatedPagesContentGroupURLForArticleURL:(NSURL *)url {
    NSParameterAssert(url);
    NSString *title = url.wmf_title;
    NSString *domain = url.wmf_domain;
    NSString *language = url.wmf_language;
    NSParameterAssert(title);
    NSParameterAssert(domain);
    NSParameterAssert(language);
    if (!title || !domain || !language) {
        return nil;
    }
    NSURL *theURL = [[self baseURL] URLByAppendingPathComponent:@"related-pages"];
    theURL = [theURL URLByAppendingPathComponent:domain];
    theURL = [theURL URLByAppendingPathComponent:language];
    theURL = [theURL URLByAppendingPathComponent:title];
    return theURL;
}

+ (nullable NSURL *)locationContentGroupURLForLocation:(CLLocation *)location {
    NSURL *url = [[self baseURL] URLByAppendingPathComponent:@"nearby"];
    url = [url URLByAppendingPathComponent:[location description]];
    return url;
}
    
+ (nullable NSURL *)locationPlaceholderContentGroupURL {
    NSURL *url = [[self baseURL] URLByAppendingPathComponent:@"nearby-placeholder"];
    return url;
}

+ (nullable NSURL *)contentGroupURLForSiteURL:(NSURL *)siteURL groupKindString:(NSString *)groupKindString {
    NSString *language = siteURL.wmf_language;
    NSString *domain = siteURL.wmf_domain;
    NSParameterAssert(domain);
    NSParameterAssert(language);
    if (!domain || !language) {
        return nil;
    }

    NSURL *urlKey = [[self baseURL] URLByAppendingPathComponent:groupKindString];
    urlKey = [urlKey URLByAppendingPathComponent:domain];
    urlKey = [urlKey URLByAppendingPathComponent:language];
    return urlKey;
}

+ (nullable NSURL *)contentGroupURLForSiteURL:(NSURL *)siteURL midnightUTCDate:(NSDate *)midnightUTCDate groupKindString:(NSString *)groupKindString {
    NSURL *urlKey = [self contentGroupURLForSiteURL:siteURL groupKindString:groupKindString];
    urlKey = [urlKey URLByAppendingPathComponent:[[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:midnightUTCDate]];
    return urlKey;
}

+ (nullable NSURL *)pictureOfTheDayContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"picture-of-the-day"];
}

+ (nullable NSURL *)randomContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"random"];
}

+ (nullable NSURL *)featuredArticleContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"featured-article"];
}

+ (nullable NSURL *)topReadContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"top-read"];
}

+ (nullable NSURL *)newsContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"news"];
}

+ (nullable NSURL *)notificationContentGroupURL {
    return [[self baseURL] URLByAppendingPathComponent:@"notification"];
}

+ (nullable NSURL *)announcementURLForSiteURL:(NSURL *)siteURL identifier:(NSString *)identifier {
    return [[self contentGroupURLForSiteURL:siteURL groupKindString:@"announcement"] URLByAppendingPathComponent:identifier];
}

- (BOOL)isForLocalDate:(NSDate *)date {
    return [self.midnightUTCDate wmf_UTCDateIsSameDateAsLocalDate:date];
}

- (BOOL)isForToday {
    return [self.midnightUTCDate wmf_UTCDateIsTodayLocal];
}

- (void)markDismissed {
    self.wasDismissed = YES;
}

- (void)updateVisibility {
    if (self.wasDismissed) {
        if (self.isVisible) {
            self.isVisible = NO;
        }
        return;
    }

    if (self.contentType != WMFContentTypeAnnouncement) {
        return;
    }

    NSArray *content = self.content;

    if (![content isKindOfClass:[NSArray class]]) {
        if (self.isVisible) {
            self.isVisible = NO;
        }
        return;
    }

    WMFAnnouncement *announcement = (WMFAnnouncement *)content.firstObject;
    if (![announcement isKindOfClass:[WMFAnnouncement class]]) {
        if (self.isVisible) {
            self.isVisible = NO;
        }
        return;
    }

    if (!announcement.startTime || !announcement.endTime) {
        if (self.isVisible) {
            self.isVisible = NO;
        }
        return;
    }

    NSDate *now = [NSDate date];
    if ([now timeIntervalSinceDate:announcement.startTime] > 0 && [announcement.endTime timeIntervalSinceDate:now] > 0) {
        if (!self.isVisible) {
            self.isVisible = YES;
        }
    } else {
        if (self.isVisible) {
            self.isVisible = NO;
        }
    }
}

@end
