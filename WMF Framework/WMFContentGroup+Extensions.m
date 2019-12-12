#import <WMF/WMFContentGroup+Extensions.h>
#import <WMF/WMFContent+CoreDataProperties.h>
#import "WMFAnnouncement.h"
@import UIKit;
#import <WMF/NSURL+WMFLinkParsing.h>
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
            URL = [WMFContentGroup continueReadingContentGroupURLForArticleURL:self.articleURL];
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
        case WMFContentGroupKindOnThisDay:
            URL = [WMFContentGroup onThisDayContentGroupURLForSiteURL:self.siteURL midnightUTCDate:self.midnightUTCDate];
            break;
        case WMFContentGroupKindNotification:
            URL = [WMFContentGroup notificationContentGroupURL];
            break;
        case WMFContentGroupKindTheme:
            URL = [WMFContentGroup themeContentGroupURL];
            break;
        case WMFContentGroupKindReadingList:
            URL = [WMFContentGroup readingListContentGroupURL];
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



- (void)updateDailySortPriorityWithSiteURLSortOrder:(nullable NSDictionary<NSString *, NSNumber *> *)siteURLSortOrderLookup {
    
    NSNumber *siteURLSortOrderNumber = nil;
    NSString *siteURLDatabaseKey = self.siteURL.wmf_databaseKey;
    
    if (siteURLDatabaseKey) {
        siteURLSortOrderNumber = siteURLSortOrderLookup[siteURLDatabaseKey];
    }
    
    NSInteger maxSortOrderByKind = 14;
    int32_t siteURLSortOrder = (int32_t)(maxSortOrderByKind * [siteURLSortOrderNumber integerValue]);
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
            updatedDailySortPriority = siteURLSortOrder + 2;
            break;
        case WMFContentGroupKindTheme:
            updatedDailySortPriority = siteURLSortOrder + 3;
            break;
        case WMFContentGroupKindFeaturedArticle:
            updatedDailySortPriority = siteURLSortOrder + 4;
            break;
        case WMFContentGroupKindTopRead:
            updatedDailySortPriority = siteURLSortOrder + 5;
            break;
        case WMFContentGroupKindNews:
            updatedDailySortPriority = siteURLSortOrder + 6;
            break;
        case WMFContentGroupKindNotification:
            updatedDailySortPriority = siteURLSortOrder + 7;
            break;
        case WMFContentGroupKindPictureOfTheDay:
            updatedDailySortPriority = 8;
            break;
        case WMFContentGroupKindOnThisDay:
            updatedDailySortPriority = siteURLSortOrder + 9;
            break;
        case WMFContentGroupKindLocationPlaceholder:
            updatedDailySortPriority = siteURLSortOrder + 10;
            break;
        case WMFContentGroupKindLocation:
            updatedDailySortPriority = siteURLSortOrder + 11;
            break;
        case WMFContentGroupKindRandom:
            updatedDailySortPriority = siteURLSortOrder + 12;
            break;
        case WMFContentGroupKindMainPage:
            updatedDailySortPriority = siteURLSortOrder + 13;
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
    return [NSURL URLWithString:self.articleURLString];
}

- (void)setArticleURL:(nullable NSURL *)articleURL {
    self.articleURLString = articleURL.absoluteString;
}

- (nullable NSURL *)siteURL {
    return [NSURL URLWithString:self.siteURLString];
}

- (void)setSiteURL:(nullable NSURL *)siteURL {
    self.siteURLString = siteURL.wmf_databaseKey;
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
    NSString *encodedTitle = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet wmf_URLArticleTitlePathComponentAllowedCharacterSet]];
    NSString *path = [NSString pathWithComponents:@[@"/continue-reading", domain, language, encodedTitle]];
    components.percentEncodedPath = path;
    return components.URL;
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
    NSString *encodedTitle = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet wmf_URLArticleTitlePathComponentAllowedCharacterSet]];
    NSString *path = [NSString pathWithComponents:@[@"/related-pages", domain, language, encodedTitle]];
    components.percentEncodedPath = path;
    return components.URL;
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
    return [NSURL wmf_URLWithDomain:domain language:language title:title fragment:nil];
}

+ (nullable NSURL *)locationContentGroupURLForLocation:(CLLocation *)location {
    NSURL *url = [[self baseURL] URLByAppendingPathComponent:@"nearby"];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%.6f/%.6f", location.coordinate.latitude, location.coordinate.longitude]];
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

+ (nullable NSURL *)onThisDayContentGroupURLForSiteURL:(NSURL *)url midnightUTCDate:(NSDate *)midnightUTCDate {
    return [self contentGroupURLForSiteURL:url midnightUTCDate:midnightUTCDate groupKindString:@"on-this-day"];
}

+ (nullable NSURL *)notificationContentGroupURL {
    return [[self baseURL] URLByAppendingPathComponent:@"notification"];
}

+ (nullable NSURL *)themeContentGroupURL {
    return [[self baseURL] URLByAppendingPathComponent:@"theme"];
}

+ (nullable NSURL *)readingListContentGroupURL {
    return [[self baseURL] URLByAppendingPathComponent:@"reading-list"];
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
    
#if WMF_ANNOUNCEMENT_DATE_IGNORE
    if (!self.isVisible) {
        self.isVisible = YES;
    }
#else
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
#endif
    
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

    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"key == %@", key];
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

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind withPredicate:(nullable NSPredicate *)predicate {
    return [self newestGroupOfKind:kind withPredicate:predicate requireIsVisible:YES];
}

- (nullable WMFContentGroup *)newestVisibleGroupOfKind:(WMFContentGroupKind)kind {
    return [self newestGroupOfKind:kind requireIsVisible:YES];
}

- (nullable WMFContentGroup *)newestGroupOfKind:(WMFContentGroupKind)kind {
    return [self newestGroupOfKind:kind requireIsVisible:NO];
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

- (nullable WMFContentGroup *)groupOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date siteURL:(NSURL *)url {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@ && siteURLString == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate, url.wmf_databaseKey];
    fetchRequest.fetchLimit = 1;
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return [contentGroups firstObject];
}

- (nullable NSArray<WMFContentGroup *> *)groupsOfKind:(WMFContentGroupKind)kind forDate:(NSDate *)date {
    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@ && midnightUTCDate == %@", @(kind), date.wmf_midnightUTCDateFromLocalDate];
    NSError *fetchError = nil;
    NSArray *contentGroups = [self executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
        return nil;
    }
    return contentGroups;
}

- (nullable WMFContentGroup *)createGroupForURL:(nullable NSURL *)URL ofKind:(WMFContentGroupKind)kind forDate:(NSDate *)date withSiteURL:(nullable NSURL *)siteURL associatedContent:(nullable id<NSCoding>)associatedContent customizationBlock:(nullable void (^)(WMFContentGroup *group))customizationBlock {
    WMFContentGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"WMFContentGroup" inManagedObjectContext:self];
    group.date = date;
    group.midnightUTCDate = date.wmf_midnightUTCDateFromLocalDate;
    group.contentGroupKind = kind;
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
                                 CLLocationDistance distance = [groupLocation distanceFromLocation:location];
                                 if (distance <= meters) {
                                     locationContentGroup = group;
                                     *stop = YES;
                                 }
                             }];
    return locationContentGroup;
}

@end
