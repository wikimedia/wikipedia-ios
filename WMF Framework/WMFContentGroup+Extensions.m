#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFContent+CoreDataProperties.h>
#import "WMFAnnouncement.h"
@import UIKit;
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSURLComponents+WMFLinkParsing.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/WMFLogging.h>
#import <WMF/NSCharacterSet+WMFLinkParsing.h>
#import <WMF/MWKLanguageLinkController.h>

@implementation WMFContentGroup (Extensions)

- (nullable NSURL *)URL {
    NSString *key = self.key;
    if (!key) {
        return nil;
    }
    NSURL *URL = [NSURL URLWithString:key];
    URL.wmf_languageVariantCode = self.variant;
    return URL;
}

- (void)setURL:(NSURL *)URL {
    // See comment for -createGroupForURL:ofKind:forDate:withSiteURL:associatedContent: for details about this assertion
    // Assert that URL is nil OR (both variant values are nil OR are equal)
    NSAssert(!URL || ((URL.wmf_languageVariantCode == nil && self.variant == nil) || [URL.wmf_languageVariantCode isEqualToString:self.variant]), @"Incoming URL value should have same language variant as WMFContentGroup instance");
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
            URL = [WMFContentGroup continueReadingContentGroupURLForArticleURL:self.articleURL];
            break;
        case WMFContentGroupKindMainPage:
            URL = [WMFContentGroup mainPageURLForSiteURL:self.siteURL];
            break;
        case WMFContentGroupKindRelatedPages:
            URL = [WMFContentGroup relatedPagesContentGroupURLForArticleURL:self.articleURL];
            break;
        case WMFContentGroupKindLocation:
            URL = [WMFContentGroup locationContentGroupURLForLocation:self.location languageVariantCode:self.siteURL.wmf_languageVariantCode];
            break;
        case WMFContentGroupKindLocationPlaceholder:
            URL = [WMFContentGroup locationPlaceholderContentGroupURLWithLanguageVariantCode:self.siteURL.wmf_languageVariantCode];
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
        case WMFContentGroupKindOnThisDay:
            URL = [WMFContentGroup onThisDayContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindNotification:
            URL = [WMFContentGroup notificationContentGroupURLWithLanguageVariantCode:self.siteURL.wmf_languageVariantCode];
            break;
        case WMFContentGroupKindTheme:
            URL = [WMFContentGroup themeContentGroupURLWithLanguageVariantCode:self.siteURL.wmf_languageVariantCode];
            break;
        case WMFContentGroupKindReadingList:
            URL = [WMFContentGroup readingListContentGroupURLWithLanguageVariantCode:self.siteURL.wmf_languageVariantCode];
            break;
        case WMFContentGroupKindAnnouncement:
            URL = [WMFContentGroup announcementURLForSiteURL:self.siteURL identifier:[(WMFAnnouncement *)self.contentPreview identifier]];
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
        case WMFContentGroupKindOnThisDay:
            self.contentType = WMFContentTypeOnThisDayEvent;
            break;
        case WMFContentGroupKindUnknown:
            assert(false);
            self.contentType = WMFContentTypeUnknown;
            break;
        case WMFContentGroupKindAnnouncement:
            self.contentType = WMFContentTypeAnnouncement;
            break;
        case WMFContentGroupKindNotification:
            self.contentType = WMFContentTypeNotification;
            break;
        case WMFContentGroupKindTheme:
            self.contentType = WMFContentTypeTheme;
            break;
        case WMFContentGroupKindReadingList:
            self.contentType = WMFContentTypeReadingList;
            break;
        case WMFContentGroupKindContinueReading:
        case WMFContentGroupKindMainPage:
        case WMFContentGroupKindRelatedPages:
        case WMFContentGroupKindLocation:
        case WMFContentGroupKindLocationPlaceholder:
        case WMFContentGroupKindRandom:
        case WMFContentGroupKindFeaturedArticle:
        default:
            self.contentType = WMFContentTypeURL;
            break;
    }
}



- (void)updateDailySortPriorityWithSortOrderByContentLanguageCode:(nullable NSDictionary<NSString *, NSNumber *> *)sortOrderByContentLanguageCode {
    
    NSNumber *contentLanguageSortOrderNumber = nil;
    NSString *contentLanguageCode = self.siteURL.wmf_contentLanguageCode;
    
    if (contentLanguageCode) {
        contentLanguageSortOrderNumber = sortOrderByContentLanguageCode[contentLanguageCode];
    }
    
    NSInteger maxSortOrderByKind = 14;
    int32_t contentLanguageSortOrder = (int32_t)(maxSortOrderByKind * [contentLanguageSortOrderNumber integerValue]);
    int32_t updatedDailySortPriority = 0;
    
    switch (self.contentGroupKind) {
        case WMFContentGroupKindUnknown:
            break;
        case WMFContentGroupKindAnnouncement:
            updatedDailySortPriority = -1;
            break;
        case WMFContentGroupKindContinueReading:
            updatedDailySortPriority = 0;
            break;
        case WMFContentGroupKindRelatedPages:
            updatedDailySortPriority = 1;
            break;
        case WMFContentGroupKindReadingList:
            updatedDailySortPriority = contentLanguageSortOrder + 2;
            break;
        case WMFContentGroupKindTheme:
            updatedDailySortPriority = contentLanguageSortOrder + 3;
            break;
        case WMFContentGroupKindFeaturedArticle:
            updatedDailySortPriority = contentLanguageSortOrder + 4;
            break;
        case WMFContentGroupKindTopRead:
            updatedDailySortPriority = contentLanguageSortOrder + 5;
            break;
        case WMFContentGroupKindNews:
            updatedDailySortPriority = contentLanguageSortOrder + 6;
            break;
        case WMFContentGroupKindNotification:
            updatedDailySortPriority = contentLanguageSortOrder + 7;
            break;
        case WMFContentGroupKindPictureOfTheDay:
            updatedDailySortPriority = 8;
            break;
        case WMFContentGroupKindOnThisDay:
            updatedDailySortPriority = contentLanguageSortOrder + 9;
            break;
        case WMFContentGroupKindLocationPlaceholder:
            updatedDailySortPriority = contentLanguageSortOrder + 10;
            break;
        case WMFContentGroupKindLocation:
            updatedDailySortPriority = contentLanguageSortOrder + 11;
            break;
        case WMFContentGroupKindRandom:
            updatedDailySortPriority = contentLanguageSortOrder + 12;
            break;
        case WMFContentGroupKindMainPage:
            updatedDailySortPriority = contentLanguageSortOrder + 13;
            break;
        default:
            break;
    }
        
    if (self.dailySortPriority == updatedDailySortPriority) {
        return;
    }
    
    self.dailySortPriority = updatedDailySortPriority;
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

- (WMFContentGroupUndoType)undoType {
    return (WMFContentGroupUndoType)self.undoTypeInteger;
}

- (void)setUndoType:(WMFContentGroupUndoType)undoType {
    self.undoTypeInteger = undoType;
}

- (nullable NSURL *)articleURL {
    NSURL *articleURL = [NSURL URLWithString:self.articleURLString];
    articleURL.wmf_languageVariantCode = self.variant;
    return articleURL;
}

- (void)setArticleURL:(nullable NSURL *)articleURL {
    // See comment for -createGroupForURL:ofKind:forDate:withSiteURL:associatedContent: for details about this assertion
    // Assert that articleURL is nil OR (both variant values are nil OR are equal)
    NSAssert(!articleURL || ((articleURL.wmf_languageVariantCode == nil && self.variant == nil) || [articleURL.wmf_languageVariantCode isEqualToString:self.variant]), @"Incoming articleURL value should have same language variant as WMFContentGroup instance");
    self.articleURLString = articleURL.absoluteString;
}

- (nullable NSURL *)siteURL {
    NSURL *siteURL = [NSURL URLWithString:self.siteURLString];
    siteURL.wmf_languageVariantCode = self.variant;
    return siteURL;
}

- (void)setSiteURL:(nullable NSURL *)siteURL {
    // See comment for -createGroupForURL:ofKind:forDate:withSiteURL:associatedContent: for details about this assertion
    // Assert that siteURL is nil OR (both variant values are nil OR are equal)
    NSAssert(!siteURL || ((siteURL.wmf_languageVariantCode == nil && self.variant == nil) || [siteURL.wmf_languageVariantCode isEqualToString:self.variant]), @"Incoming siteURL value should have same language variant as WMFContentGroup instance");
    self.siteURLString = siteURL.wmf_databaseKey;
}

- (nullable WMFInMemoryURLKey *)inMemoryKey {
    return self.URL.wmf_inMemoryKey;
}

- (void)setFullContentObject:(NSObject<NSCoding> *)fullContentObject {
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSAssert(moc != nil, @"nil moc");
    if (!moc) {
        return;
    }
    if ([fullContentObject isKindOfClass:[NSArray class]] || [fullContentObject isKindOfClass:[NSSet class]]) {
        self.countOfFullContent = @([(id)fullContentObject count]);
    }
    WMFContent *fullContent = self.fullContent;
    if (!fullContentObject) {
        if (fullContent) {
            [moc deleteObject:fullContent];
            self.fullContent = nil;
            return;
        }
        return;
    }

    if (!fullContent) {
        fullContent = (WMFContent *)[NSEntityDescription insertNewObjectForEntityForName:@"WMFContent" inManagedObjectContext:moc];
        self.fullContent = fullContent;
    }
    fullContent.object = fullContentObject;
}

- (NSInteger)featuredContentIndex {
    if (self.featuredContentIdentifier == nil) {
        return NSNotFound;
    }
    return self.featuredContentIdentifier.integerValue;
}

- (void)setFeaturedContentIndex:(NSInteger)index {
    if (index == NSNotFound) {
        self.featuredContentIdentifier = nil;
    } else {
        self.featuredContentIdentifier = [NSString stringWithFormat:@"%lli", (long long)index];
    }
}

- (void)updateContentPreviewWithContent:(id)content {
    if (!content) {
        return;
    }
    NSInteger contentLimit = 3;
    NSArray *contentArray = nil;
    if ([content isKindOfClass:[NSArray class]]) {
        contentArray = (NSArray *)content;
    }
    switch (self.contentGroupKind) {
        case WMFContentGroupKindOnThisDay: {
            NSInteger featuredEventIndex = self.featuredContentIndex;
            if (featuredEventIndex >= 0 && featuredEventIndex < contentArray.count) {
                NSInteger startIndex = featuredEventIndex;
                NSInteger length = startIndex + 1 < contentArray.count ? 2 : 1;
                NSRange range = NSMakeRange(startIndex, length);
                // If we have only the last item but there's more than one, move back one so we get 2 total.
                // Only do so in this specific case so we usually have the `featuredContent` first (it's chosen based on a score weighing its various properties).
                BOOL shouldBackUpByOne = range.length == 1 && startIndex > 0 && contentArray.count > 1;
                if (shouldBackUpByOne) {
                    range = NSMakeRange(startIndex - 1, 2);
                }
                self.contentPreview = [contentArray subarrayWithRange:range];
            }
        } break;
        case WMFContentGroupKindTopRead:
            contentLimit = 5;
        case WMFContentGroupKindRelatedPages:
        case WMFContentGroupKindLocation: {
            if (contentArray.count > contentLimit) {
                self.contentPreview = [contentArray subarrayWithRange:NSMakeRange(0, contentLimit)];
            } else if (contentArray.count > 0) {
                self.contentPreview = contentArray;
            }

        } break;
        case WMFContentGroupKindMainPage:
        case WMFContentGroupKindNotification:
        case WMFContentGroupKindLocationPlaceholder:
        case WMFContentGroupKindPictureOfTheDay:
        case WMFContentGroupKindRandom:
        case WMFContentGroupKindFeaturedArticle:
        case WMFContentGroupKindTheme:
        case WMFContentGroupKindReadingList:
        case WMFContentGroupKindAnnouncement:
        case WMFContentGroupKindContinueReading:
        case WMFContentGroupKindNews:
        case WMFContentGroupKindUnknown:
        default: {
            id<NSCoding> firstObject = contentArray.firstObject ?: content;
            if (firstObject) {
                self.contentPreview = firstObject;
            }
        } break;
    }
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
    theURL.wmf_languageVariantCode = URL.wmf_languageVariantCode;
    return theURL;
}

+ (nullable NSURL *)continueReadingContentGroupURLForArticleURL:(NSURL *)url {
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
    NSURLComponents *components = [NSURLComponents componentsWithURL:[self baseURL] resolvingAgainstBaseURL:NO];
    NSString *encodedTitle = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet wmf_encodeURIComponentAllowedCharacterSet]];
    NSString *path = [NSString pathWithComponents:@[@"/continue-reading", domain, language, encodedTitle]];
    components.percentEncodedPath = path;
    return [components wmf_URLWithLanguageVariantCode:url.wmf_languageVariantCode];
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
    NSURLComponents *components = [NSURLComponents componentsWithURL:[self baseURL] resolvingAgainstBaseURL:NO];
    NSString *encodedTitle = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet wmf_encodeURIComponentAllowedCharacterSet]];
    NSString *path = [NSString pathWithComponents:@[@"/related-pages", domain, language, encodedTitle]];
    components.percentEncodedPath = path;
    return [components wmf_URLWithLanguageVariantCode:url.wmf_languageVariantCode];
}

+ (nullable NSURL *)articleURLForRelatedPagesContentGroupURL:(nullable NSURL *)url {
    if (!url) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSArray *pathComponents = components.percentEncodedPath.pathComponents;
    if (pathComponents.count < 5) {
        return nil;
    }
    NSString *domain = pathComponents[2];
    NSString *language = pathComponents[3];
    NSString *title = [pathComponents[4] stringByRemovingPercentEncoding];
    NSURL *theURL = [NSURL wmf_URLWithDomain:domain language:language title:title fragment:nil];
    theURL.wmf_languageVariantCode = url.wmf_languageVariantCode;
    return theURL;
}

+ (nullable NSURL *)locationContentGroupURLForLocation:(CLLocation *)location languageVariantCode:(NSString *)languageVariantCode {
    NSURL *url = [[self baseURL] URLByAppendingPathComponent:@"nearby"];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%.6f/%.6f", location.coordinate.latitude, location.coordinate.longitude]];
    url.wmf_languageVariantCode = languageVariantCode;
    return url;
}

+ (nullable NSURL *)locationPlaceholderContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode {
    NSURL *url = [[self baseURL] URLByAppendingPathComponent:@"nearby-placeholder"];
    url.wmf_languageVariantCode = languageVariantCode;
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
    urlKey.wmf_languageVariantCode = siteURL.wmf_languageVariantCode;
    return urlKey;
}

+ (nullable NSURL *)contentGroupURLForSiteURL:(NSURL *)siteURL midnightUTCDate:(NSDate *)midnightUTCDate groupKindString:(NSString *)groupKindString {
    NSURL *urlKey = [self contentGroupURLForSiteURL:siteURL groupKindString:groupKindString];
    urlKey = [urlKey URLByAppendingPathComponent:[[NSDateFormatter wmf_englishUTCSlashDelimitedYearMonthDayFormatter] stringFromDate:midnightUTCDate]];
    urlKey.wmf_languageVariantCode = siteURL.wmf_languageVariantCode;
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

+ (nullable NSURL *)onThisDayContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"on-this-day"];
}

+ (nullable NSURL *)notificationContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode {
    NSURL *URL = [[self baseURL] URLByAppendingPathComponent:@"notification"];
    URL.wmf_languageVariantCode = languageVariantCode;
    return URL;
}

+ (nullable NSURL *)themeContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode {
    NSURL *URL = [[self baseURL] URLByAppendingPathComponent:@"theme"];
    URL.wmf_languageVariantCode = languageVariantCode;
    return URL;
}

+ (nullable NSURL *)readingListContentGroupURLWithLanguageVariantCode:(NSString *)languageVariantCode {
    NSURL *URL = [[self baseURL] URLByAppendingPathComponent:@"reading-list"];
    URL.wmf_languageVariantCode = languageVariantCode;
    return URL;
}

+ (nullable NSURL *)announcementURLForSiteURL:(NSURL *)siteURL identifier:(NSString *)identifier {
    NSURL *URL = [[self contentGroupURLForSiteURL:siteURL groupKindString:@"announcement"] URLByAppendingPathComponent:identifier];
    URL.wmf_languageVariantCode = siteURL.wmf_languageVariantCode;
    return URL;
}

- (BOOL)isForLocalDate:(NSDate *)date {
    return [self.midnightUTCDate wmf_UTCDateIsSameDateAsLocalDate:date];
}

- (BOOL)isForToday {
    return [self.midnightUTCDate wmf_UTCDateIsTodayLocal];
}

- (BOOL)isRTL {
    return [MWKLanguageLinkController isLanguageRTLForContentLanguageCode:self.siteURL.wmf_language];
}

- (void)markDismissed {
    self.wasDismissed = YES;
}

- (void)updateVisibilityForUserIsLoggedIn:(BOOL)isLoggedIn {
    if (self.wasDismissed) {
        if (self.isVisible) {
            self.isVisible = NO;
        }
        return;
    }

    if (self.contentType != WMFContentTypeAnnouncement) {
        return;
    }
    
    dispatch_block_t markInvisible = ^{
        if (self.isVisible) {
            self.isVisible = NO;
        }
    };

    WMFAnnouncement *announcement = (WMFAnnouncement *)self.contentPreview;
    if (![announcement isKindOfClass:[WMFAnnouncement class]]) {
        markInvisible();
        return;
    }
    
    if (announcement.beta.boolValue) { // ignore beta announcements
        markInvisible();
        return;
    }
    
    if (announcement.loggedIn && announcement.loggedIn.boolValue != isLoggedIn) {
        markInvisible();
        return;
    }
    
    if (announcement.readingListSyncEnabled) { // ignore reading list announcements, regardless of true or false
        markInvisible();
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

@implementation NSManagedObjectContext (WMFContentGroup)

- (void)enumerateContentGroupsWithBlock:(void (^)(WMFContentGroup *_Nonnull section, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return;
    }
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        block(section, stop);
    }];
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind sortedByDescriptors:(nullable NSArray *)sortDescriptors {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    fetchRequest.sortDescriptors = sortDescriptors;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError || !contentGroups) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return @[];
    }
    return contentGroups;
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)sortKey ascending:(BOOL)ascending {
    return [self contentGroupsOfKind:kind sortedByDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending]]];
}

- (NSArray<WMFContentGroup *> *)contentGroupsOfKind:(WMFContentGroupKind)kind {
    return [self contentGroupsOfKind:kind sortedByDescriptors:nil];
}

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind sortedByKey:(NSString *)key ascending:(BOOL)ascending withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSArray<WMFContentGroup *> *contentGroups = [self contentGroupsOfKind:kind sortedByKey:key ascending:ascending];
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        block(section, stop);
    }];
}

- (void)enumerateContentGroupsOfKind:(WMFContentGroupKind)kind withBlock:(void (^)(WMFContentGroup *_Nonnull group, BOOL *stop))block {
    if (!block) {
        return;
    }
    NSArray<WMFContentGroup *> *contentGroups = [self contentGroupsOfKind:kind];
    [contentGroups enumerateObjectsUsingBlock:^(WMFContentGroup *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        block(section, stop);
    }];
}

- (nullable WMFContentGroup *)contentGroupForURL:(NSURL *)URL {
    NSParameterAssert(URL);
    if (!URL) {
        return nil;
    }

    NSString *key = [WMFContentGroup databaseKeyForURL:URL];
    if (!key) {
        return nil;
    }
    
    NSString *variant = URL.wmf_languageVariantCode;

    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"key == %@ && variant == %@", key, variant];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind requireIsVisible:(BOOL)isVisibleRequired {
    return [self newestGroupOfKind:kind withPredicate:nil requireIsVisible:isVisibleRequired];
}

- (nullable WMFContentGroup *)newestGroupWithPredicate:(nullable NSPredicate *)predicate {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"midnightUTCDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"dailySortPriority" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind withPredicate:(nullable NSPredicate *)additionalPredicate requireIsVisible:(BOOL)isVisibleRequired {
    NSPredicate *predicate = nil;
    if (isVisibleRequired) {
        predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && isVisible == YES", @(kind)];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    }
    NSCompoundPredicate *compoundPredicate = nil;
    if (additionalPredicate) {
        compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, additionalPredicate]];
    }
    return [self newestGroupWithPredicate:compoundPredicate ?: predicate];
}

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind forSiteURL:(nullable NSURL *)siteURL {
    if (!siteURL) {
        return [self newestGroupOfKind:kind requireIsVisible:YES];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"siteURLString == %@ && variant = %@", siteURL.wmf_databaseKey, siteURL.wmf_languageVariantCode];
    return [self newestVisibleGroupOfKind:kind withPredicate:predicate];
}

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind withPredicate:(nullable NSPredicate *)predicate {
    return [self newestGroupOfKind:kind withPredicate:predicate requireIsVisible:YES];
}

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind {
    return [self newestGroupOfKind:kind requireIsVisible:YES];
}

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind {
    return [self newestGroupOfKind:kind requireIsVisible:NO];
}

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind forSiteURL:(nullable NSURL *)siteURL {
    if (!siteURL) {
        return [self newestGroupOfKind:kind requireIsVisible:NO];
    }    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"siteURLString == %@ && variant = %@", siteURL.wmf_databaseKey, siteURL.wmf_languageVariantCode];
    return [self newestGroupOfKind:kind withPredicate:predicate requireIsVisible:NO];
}

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date siteURL:(NSURL *)siteURL {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@ && siteURLString == %@ && variant == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate, siteURL.wmf_databaseKey, siteURL.wmf_languageVariantCode];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable NSArray<WMFContentGroup *> *)orderedGroupsOfKind:(WMFContentGroupKind)kind withPredicate:(nullable NSPredicate *)predicate {
    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(kind)];
    NSPredicate *finalPredicate = basePredicate;
    if (predicate) {
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate, predicate]];
        finalPredicate = compoundPredicate;
    }
    
    NSArray<NSSortDescriptor *> *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"midnightUTCDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"dailySortPriority" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    return [self groupsWithPredicate:finalPredicate sortDescriptors:sortDescriptors];
}

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate];
    return [self groupsWithPredicate:predicate sortDescriptors:nil];
}

- (nullable NSArray<WMFContentGroup *> *)groupsWithPredicate: (nonnull NSPredicate *)predicate sortDescriptors: (nullable  NSArray<NSSortDescriptor *> *)sortDescriptors {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = predicate;
    if (sortDescriptors) {
        fetchRequest.sortDescriptors = sortDescriptors;
    }
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return contentGroups;
}

/* There is an important dependency between the langauge variant property and the computed properties siteURL, articleURL, and URL. Each returned URL uses the value of the siteURLString, articleURLString, or key properties, respectively. Each also sets the value of the variant property as the wmf_languageVariantCode of the created URL. The langauge variant should remain consistent for the lifetime of a WMFContentGroup object. When created, the variant comes from either the passed-in URL if present, or the siteURL. Note that this property is set *before* the siteURL and URL properties in this method.
 
    The setter methods for siteURL, articleURL, and URL assert that the variant on those incoming URLs equals the variant property of the group. This should always be true. The assertions ensure that these assumptions are true in all uses and that future changes do not unexpectedly violate that assumption.
 */
- (nullable WMFContentGroup *)createGroupForURL:(nullable NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {
    WMFContentGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"WMFContentGroup" inManagedObjectContext:self];
    group.date = date;
    group.midnightUTCDate = date.wmf_midnightUTCDateFromLocalDate;
    group.contentGroupKind = kind;
    // Important to set variant before siteURL or URL properties. See comment above for details.
    group.variant = URL ? URL.wmf_languageVariantCode : (siteURL ? siteURL.wmf_languageVariantCode : nil);
    group.siteURL = siteURL;
    group.fullContentObject = associatedContent;
    [group updateContentPreviewWithContent:associatedContent];

    if (customizationBlock) {
        customizationBlock(group);
    }

    if (URL) {
        group.URL = URL;
    } else {
        [group updateKey];
    }
    [group updateContentType];

    return group;
}

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent {
    return [self createGroupForURL:nil ofKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent customizationBlock:nil];
}

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {
    return [self createGroupForURL:nil ofKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent customizationBlock:customizationBlock];
}

- (nullable WMFContentGroup *)fetchOrCreateGroupForURL:(NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {

    WMFContentGroup *group = [self contentGroupForURL:URL];
    if (group) {
        group.date = date;
        group.midnightUTCDate = date.wmf_midnightUTCDateFromLocalDate;
        group.contentGroupKind = kind;
        group.fullContentObject = associatedContent;
        group.siteURL = siteURL;
        [group updateContentPreviewWithContent:associatedContent];
        if (customizationBlock) {
            customizationBlock(group);
        }
    } else {
        group = [self createGroupForURL:URL ofKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent customizationBlock:customizationBlock];
    }

    return group;
}

- (nullable WMFContentGroup *)createGroupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent inManagedObjectContext:(nonnull NSManagedObjectContext *)moc {
    return [self createGroupOfKind:kind forDate:date withSiteURL:siteURL associatedContent:associatedContent customizationBlock:NULL];
}

- (void)removeContentGroup:(WMFContentGroup *)group {
    NSParameterAssert(group);
    [self deleteObject:group];
}

- (void)removeContentGroups:(NSArray<WMFContentGroup *> *)contentGroups {
    for (WMFContentGroup *group in contentGroups) {
        [self deleteObject:group];
    }
}

- (void)removeAllContentGroupsOfKind:(WMFContentGroupKind)kind {
    NSArray *groups = [self contentGroupsOfKind:kind];
    [self removeContentGroups:groups];
}

- (nullable WMFContentGroup *)locationContentGroupWithSiteURL:(nullable NSURL *)siteURL withinMeters:(CLLocationDistance)meters ofLocation:(CLLocation *)location {
    __block WMFContentGroup *locationContentGroup = nil;
    NSString *siteURLString = siteURL.wmf_databaseKey;
    NSString *siteURLVariantCode = siteURL.wmf_languageVariantCode;
    [self enumerateContentGroupsOfKind:WMFContentGroupKindLocation
                             withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                 CLLocation *groupLocation = group.location;
                                 if (!groupLocation) {
                                     return;
                                 }
                                 NSString *groupSiteURLString = group.siteURL.wmf_databaseKey;
                                 if (siteURLString && groupSiteURLString && ![siteURLString isEqualToString:groupSiteURLString]) {
                                     return;
                                 }
                                 NSString *groupVariantCode = group.variant;
                                 if (siteURLVariantCode && groupVariantCode && ![siteURLVariantCode isEqualToString:groupVariantCode]) {
                                     return;
                                 }
                                 CLLocationDistance distance = [groupLocation distanceFromLocation:location];
                                 if (distance <= meters) {
                                     locationContentGroup = group;
                                     *stop = YES;
                                 }
                             }];
    return locationContentGroup;
}

@end

#pragma mark - Language Variant Propagation

/* Since a serialized NSURL has no notion of a language variant, when the contentPreview property of a WMFContentGroup instance or the object property of a WMFContent instance is deserialized, the variant of the content group needs to be propagated to URL values in the deserialized object graph.
 
    By doing this in -awakeFromFetch, the propagation does not happen until the values for the instance is faulted in. It also ensures that propagation happens once per fetch. Note that values set when an object is initilized or a property is set are expected to already have the language variant correctly set on itself or subelements.
 
    The serialized objects are expected to be of type NSURL, WMFMTLModel subclasses, or collections of those types.
 */

@implementation WMFContentGroup (LanguageVariantPropagation)

- (void)awakeFromFetch {
    [super awakeFromFetch];
    [WMFContentGroup propagateLanguageVariant: self.variant toPropertyValue: (NSObject<NSCoding> *)self.contentPreview];
}

+ (void)propagateLanguageVariant:(nullable NSString *)variant toPropertyValue:(NSObject<NSCoding> *)inObject {
    if ([inObject isKindOfClass:[NSArray class]] ||  [inObject isKindOfClass:[NSSet class]]) {
        id<NSFastEnumeration>collection = (id<NSFastEnumeration>)inObject;
        for (id element in collection) {
            [self propagateVariant:variant ToElement:element];
        }
    }
    else {
        [self propagateVariant:variant ToElement:inObject];
    }
}

+ (void)propagateVariant:(nullable NSString *)variant ToElement:(id)element {
    if ([element respondsToSelector:@selector(propagateLanguageVariantCode:)]) {
        [element propagateLanguageVariantCode:variant];
    } else if ([element isKindOfClass:[NSURL class]]) {
        ((NSURL *)element).wmf_languageVariantCode = variant;
    }
}

@end

@implementation WMFContent (LanguageVariantPropagation)
- (void)awakeFromFetch {
    [super awakeFromFetch];
    [WMFContentGroup propagateLanguageVariant: self.contentGroup.variant toPropertyValue: (NSObject<NSCoding> *)self.object];
}
@end

