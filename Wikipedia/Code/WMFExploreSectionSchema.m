
#import "WMFExploreSectionSchema_Testing.h"
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"
#import "WMFExploreSection.h"
#import "Wikipedia-Swift.h"
#import "NSDate+Utilities.h"
#import "WMFLocationManager.h"
#import "WMFRelatedSectionBlackList.h"
#import "NSDate+WMFMostReadDate.h"
#import "NSCalendar+WMFCommonCalendars.h"
#import <Tweaks/FBTweakInline.h>

@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const WMFHomeMinimumAutomaticReloadTime      = 600.0; //10 minutes
static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 24 * 60 * 60; //24 hours
static NSTimeInterval const WMFTimeBeforeRefreshingRandom          = 60 * 60 * 24 * 7; //7 days


static CLLocationDistance const WMFMinimumDistanceBeforeUpdatingNearby = 500.0;

@interface WMFExploreSectionSchema ()<WMFLocationManagerDelegate>

@property (nonatomic, strong, readwrite) NSURL* siteURL;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readwrite) MWKHistoryList* historyPages;
@property (nonatomic, strong, readwrite) WMFRelatedSectionBlackList* blackList;

@property (nonatomic, strong) WMFLocationManager* locationManager;

@property (nonatomic, strong, readwrite, nullable) NSDate* lastUpdatedAt;

@property (nonatomic, strong, readwrite) NSArray<WMFExploreSection*>* sections;

@property (nonatomic, strong, readwrite) NSURL* fileURL;

@property (nonatomic, strong) dispatch_queue_t saveQueue;

@end


@implementation WMFExploreSectionSchema
@synthesize sections = _sections;

- (dispatch_queue_t)saveQueue {
    if (_saveQueue == nil) {
        const char* queueName = [NSString stringWithFormat:@"org.wikimedia.wikipedia.explore.schema.save.%p", self].UTF8String;
        self.saveQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);;
    }
    return _saveQueue;
}

- (NSString*)description {
    // HAX: prevent this from logging all its properties in its description, as this causes recursion to
    // WMFLocationManager.description
    return [NSString stringWithFormat:@"<%@: %p>", [self class], self];
}

#pragma mark - Setup

+ (instancetype)schemaWithSiteURL:(NSURL*)siteURL
                         savedPages:(MWKSavedPageList*)savedPages
                            history:(MWKHistoryList*)history
                          blackList:(WMFRelatedSectionBlackList*)blackList {
    return [self schemaWithSiteURL:siteURL
                          savedPages:savedPages
                             history:history
                           blackList:blackList
                     locationManager:[WMFLocationManager coarseLocationManager]
                                file:[self defaultSchemaURL]];
}

+ (instancetype)schemaWithSiteURL:(NSURL*)siteURL
                         savedPages:(MWKSavedPageList*)savedPages
                            history:(MWKHistoryList*)history
                          blackList:(WMFRelatedSectionBlackList*)blackList
                    locationManager:(WMFLocationManager*)locationManager
                               file:(NSURL*)fileURL {
    NSParameterAssert(siteURL);
    NSParameterAssert(savedPages);
    NSParameterAssert(history);
    NSParameterAssert(blackList);
    NSParameterAssert(fileURL);

    WMFExploreSectionSchema* schema = [self schemaFromFileAtURL:fileURL] ? : [[WMFExploreSectionSchema alloc] init];
    schema.siteURL         = [siteURL wmf_siteURL];
    schema.savedPages        = savedPages;
    schema.historyPages      = history;
    schema.blackList         = blackList;
    schema.fileURL           = fileURL;
    schema.locationManager   = locationManager;
    locationManager.delegate = schema;

    [schema update:YES];

    return schema;
}

- (void)setBlackList:(WMFRelatedSectionBlackList*)blackList {
    if (_blackList) {
        [self.KVOController unobserve:_blackList];
    }

    _blackList = blackList;

    [self.KVOController observe:_blackList keyPath:WMF_SAFE_KEYPATH(_blackList, entries) options:0 block:^(WMFExploreSectionSchema* observer, WMFRelatedSectionBlackList* object, NSDictionary* change) {
        [observer updateWithChangesInBlackList:object];
    }];
}

/**
 *  Sections used to "seed" a user's "feed" with an initial set of content.
 *
 *  Omits certain sections which are not guaranteed to be available (e.g. featured articles & nearby).
 *
 *  @return An array of sections that can be used to start the "feed" from scratch.
 */
- (NSArray<WMFExploreSection*>*)startingSchema {
    return @[[WMFExploreSection mainPageSectionWithSiteURL:self.siteURL],
             [WMFExploreSection randomSectionWithSiteURL:self.siteURL]];
}

#pragma mark - Main Article

- (BOOL)urlIsForMainArticle:(NSURL*)url {
    NSURL* mainArticleURL = [NSURL wmf_mainPageURLForLanguage:url.wmf_language];
    return ([url isEqual:mainArticleURL]);
}

#pragma mark - Sections

- (NSArray<WMFExploreSection*>*)sections {
    if (!_sections) {
        // required to enforce nonnull compliance when created for the first time
        _sections = @[];
    }
    return _sections;
}

- (void)updateSections:(NSArray<WMFExploreSection*>*)sections {
    if (self.sections == sections) {
        // not bothering with equality check here since it could be expensive when list is long
        return;
    }

    if (sections) {
        self.sections = [sections sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
            return [obj1 compare:obj2];
        }];
    } else {
        // must be nonnull
        self.sections = @[];
    }

    [self.delegate sectionSchemaDidUpdateSections:self];

    [self save];
}

- (void)removeSection:(WMFExploreSection*)section {
    NSUInteger index = [self.sections indexOfObject:section];
    if (index == NSNotFound) {
        return;
    }
    NSMutableArray* sections = [self.sections mutableCopy];
    [sections removeObject:section];
    self.sections = sections;
    [self.delegate sectionSchema:self didRemoveSection:section atIndex:index];
    [self save];
}

#pragma mark - Update

- (void)updateSiteURL:(NSURL*)siteURL {
    if ([siteURL isEqual:self.siteURL]) {
        return;
    }
    self.siteURL = siteURL;
    [self update:YES];
}

- (void)update {
    [self update:NO];
}

- (BOOL)update:(BOOL)force {
    [self.locationManager restartLocationMonitoring];

    if (!FBTweakValue(@"Explore", @"General", @"Always update on launch", NO)
        && !force
        && self.lastUpdatedAt
        && [[NSDate date] timeIntervalSinceDate:self.lastUpdatedAt] < WMFHomeMinimumAutomaticReloadTime) {
        return [self updateContinueReading];
    }

    //Get updated static sections
    NSMutableArray<WMFExploreSection*>* sections = [[self staticSections] mutableCopy];

    [sections addObjectsFromArray:[self featuredSections]];
    [sections addObjectsFromArray:[self mostReadSectionsWithUpdateIfNeeded]];
    [sections addObjectsFromArray:[self nearbySections]];

    [sections addObjectsFromArray:[self pictureOfTheDaySections]];

    //Add Saved and History
    NSArray<WMFExploreSection*>* recent = [self historyAndSavedPageSections];
    if ([recent count] > 0) {
        [sections addObjectsFromArray:recent];
    }

    self.lastUpdatedAt = [NSDate date];

    [self updateSections:sections];

    return YES;
}

- (BOOL)updateContinueReading {
    WMFExploreSection* old = [self existingContinueReadingSection];
    WMFExploreSection* new = [self continueReadingSection];
    if (WMF_EQUAL(old.articleURL, isEqual:, new.articleURL)) {
        return NO;
    }

    //Get updated static sections
    NSMutableArray<WMFExploreSection*>* sections = [[self sections] mutableCopy];
    [sections removeObject:old];

    if (new) {
        [sections insertObject:new atIndex:0];
    }
    [self updateSections:sections];
    return YES;
}

- (void)insertNearbySectionWithLocationIfNeeded:(CLLocation*)location {
    NSParameterAssert(location);

    NSMutableArray<WMFExploreSection*>* existingNearbySections = [[self nearbySections] mutableCopy];

    WMFExploreSection* closeEnough = [existingNearbySections bk_match:^BOOL (WMFExploreSection* oldNearby) {
        //Don't add a new one if we have one that is minimum distance
        if (oldNearby.location
            && [location distanceFromLocation:oldNearby.location] < WMFMinimumDistanceBeforeUpdatingNearby
            && oldNearby.placemark != nil) {
            return YES;
        }

        //Don't add more than one more in a single day
        if (oldNearby.location && [oldNearby.dateCreated isToday] && oldNearby.placemark != nil) {
            return YES;
        }

        return NO;
    }];

    if (closeEnough != nil) {
        return;
    }

    @weakify(self);
    [self.locationManager reverseGeocodeLocation:location].then(^(CLPlacemark* _Nullable placemark) {
        @strongify(self);
        if (!self) {
            return;
        }
        NSMutableArray<WMFExploreSection*>* sections = [self.sections mutableCopy];
        [sections bk_performReject:^BOOL (WMFExploreSection* obj) {
            return obj.type == WMFExploreSectionTypeNearby;
        }];

        [existingNearbySections addObject:[self nearbySectionWithLocation:location placemark:placemark]];

        NSUInteger max = [WMFExploreSection maxNumberOfSectionsForType:WMFExploreSectionTypeNearby];

        [existingNearbySections sortWithOptions:NSSortStable
                                usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
            return -[obj1.dateCreated compare:obj2.dateCreated];
        }];

        NSArray *trimmedExistingNearbySections = [existingNearbySections wmf_arrayByTrimmingToLength:max];
        [sections addObjectsFromArray:trimmedExistingNearbySections];
        [self updateSections:sections];
    }).catch(^(NSError* error) {
        DDLogWarn(@"Suppressing geocoding error: %@", error);
        return nil;
    });
}

- (void)removeNearbySection {
    NSMutableArray<WMFExploreSection*>* sections = [self.sections mutableCopy];
    [sections bk_performReject:^BOOL (WMFExploreSection* obj) {
        return obj.type == WMFExploreSectionTypeNearby;
    }];
    [self updateSections:sections];
}

- (void)updateWithChangesInBlackList:(WMFRelatedSectionBlackList*)blackList {
    //enumerate in reverse so that indexes are always correct
    [[blackList.entries wmf_mapAndRejectNil:^id (NSURL* obj) {
        return [self existingSectionForArticleURL:obj];
    }] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WMFExploreSection* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        [self removeSection:obj];
    }];
}

#pragma mmrk - Section Creation

/**
 *  Sections which should always be present in the "feed" (i.e. everything that isn't site specific).
 *
 *  @return An array of all existing site-independent sections.
 */
- (NSArray<WMFExploreSection*>*)staticSections {
    NSMutableArray<WMFExploreSection*>* sections = [NSMutableArray array];

    [sections wmf_safeAddObject:[self randomSection]];
    [sections addObject:[self mainPageSection]];
    [sections wmf_safeAddObject:[self continueReadingSection]];

    return sections;
}

- (WMFExploreSection*)randomSection {
    WMFExploreSection* random = [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypeRandom && [obj.siteURL isEqual:self.siteURL]) {
            return YES;
        }
        return NO;
    }];

    MWKHistoryEntry* lastEntry = [self.historyPages.entries firstObject];
    if (lastEntry && [[NSDate date] timeIntervalSinceDate:lastEntry.date] > WMFTimeBeforeRefreshingRandom) {
        random = [WMFExploreSection randomSectionWithSiteURL:self.siteURL];
    }

    //Always return a random section
    if (!random) {
        random = [WMFExploreSection randomSectionWithSiteURL:self.siteURL];
    }

    return random;
}

- (NSArray<WMFExploreSection*>*)nearbySections {
    NSArray<WMFExploreSection*>* nearby = [self.sections bk_select:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypeNearby && obj.location != nil && obj.siteURL != nil) {
            return YES;
        }
        return NO;
    }];

    return nearby;
}

- (nullable WMFExploreSection*)nearbySectionWithLocation:(CLLocation*)location placemark:(nullable CLPlacemark*)placemark {
    NSParameterAssert(location);
    if (!location || [WMFLocationManager isDeniedOrDisabled]) {
        return nil;
    }
    return [WMFExploreSection nearbySectionWithLocation:location placemark:placemark siteURL:self.siteURL];
}

/**
 *  Retrieve an updated list of "most read" sections, incorporating prior ones.
 *
 *  Selects all "most read" sections from the receiver and, if possible, appends an additional section for the most
 *  recent data from the current site.
 *
 *  @return An array of "most read" sections that should be in an updated version of the receiver.
 */
- (NSArray<WMFExploreSection*>*)mostReadSectionsWithUpdateIfNeeded {
    NSMutableArray<WMFExploreSection*>* mostReadSections = [[self.sections bk_select:^BOOL (WMFExploreSection* section) {
        return section.type == WMFExploreSectionTypeMostRead && section.siteURL != nil && section.mostReadFetchDate != nil;
    }] mutableCopy];

    WMFExploreSection* latestMostReadSection = [self newMostReadSectionWithLatestPopulatedDate];

    BOOL containsLatestSectionEquivalent = [mostReadSections bk_any:^BOOL (WMFExploreSection* mostReadSection) {
        BOOL const matchesDay = [[NSCalendar wmf_utcGregorianCalendar]
                                 compareDate:mostReadSection.mostReadFetchDate
                                       toDate:latestMostReadSection.mostReadFetchDate
                            toUnitGranularity:NSCalendarUnitDay] == NSOrderedSame;
        BOOL const matchesSite = [mostReadSection.siteURL isEqual:latestMostReadSection.siteURL];
        return matchesDay && matchesSite;
    }];

    if (!containsLatestSectionEquivalent) {
        [mostReadSections addObject:latestMostReadSection];
    }

    NSUInteger max = FBTweakValue(@"Explore", @"Sections", @"Max number of most read", [WMFExploreSection maxNumberOfSectionsForType:WMFExploreSectionTypeMostRead]);

    //Sort by date
    [mostReadSections sortWithOptions:NSSortStable
                      usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [mostReadSections wmf_arrayByTrimmingToLength:max];
}

- (nullable WMFExploreSection*)newMostReadSectionWithLatestPopulatedDate {
    WMFExploreSection* section = [WMFExploreSection mostReadSectionForDate:[NSDate wmf_latestMostReadDataWithLikelyAvailableData]
                                                                 siteURL:self.siteURL];

    if (!section.siteURL || !section.mostReadFetchDate) {
        return nil;
    } else {
        return section;
    }
}

- (NSArray<WMFExploreSection*>*)featuredSections {
    NSArray* existingFeaturedArticleSections = [self.sections bk_select:^BOOL (WMFExploreSection* obj) {
        return obj.type == WMFExploreSectionTypeFeaturedArticle;
    }];

    //Don't add new ones if we aren't in english
    NSMutableArray* featured = [existingFeaturedArticleSections mutableCopy];

    BOOL const containsTodaysFeaturedArticle = [featured bk_any:^BOOL (WMFExploreSection* obj) {
        NSAssert(obj.type == WMFExploreSectionTypeFeaturedArticle,
                 @"List should only contain featured sections, got %@", featured);
        return [obj.dateCreated isToday];
    }];

    if (!containsTodaysFeaturedArticle) {
        [featured wmf_safeAddObject:[WMFExploreSection featuredArticleSectionWithSiteURLIfSupported:self.siteURL]];
    }

    NSUInteger max = FBTweakValue(@"Explore", @"Sections", @"Max number of featured", [WMFExploreSection maxNumberOfSectionsForType:WMFExploreSectionTypeFeaturedArticle]);

    //Sort by date
    [featured sortWithOptions:NSSortStable
              usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [featured wmf_arrayByTrimmingToLength:max];
}

- (WMFExploreSection*)mainPageSection {
    WMFExploreSection* main = [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypeMainPage && [obj.siteURL isEqual:self.siteURL]) {
            return YES;
        }
        return NO;
    }];

    //If it's a new day and we havent created a new main page section, create it now
    if ([main.dateCreated isToday] && [main.siteURL isEqual:self.siteURL]) {
        return main;
    }

    return [WMFExploreSection mainPageSectionWithSiteURL:self.siteURL];
}

- (NSArray<WMFExploreSection*>*)pictureOfTheDaySections {
    NSMutableArray<WMFExploreSection*>* existingSections = [[self.sections bk_select:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypePictureOfTheDay) {
            return YES;
        }
        return NO;
    }] mutableCopy];

    WMFExploreSection* todaySection = [existingSections bk_match:^BOOL (WMFExploreSection* existingSection) {
        //Only one section per day
        if ([existingSection.dateCreated isToday]) {
            return YES;
        }

        return NO;
    }];

    if (todaySection == nil) {
        [existingSections addObject:[WMFExploreSection pictureOfTheDaySectionWithDate:[NSDate date]]];
    }

    NSUInteger max = [WMFExploreSection maxNumberOfSectionsForType:WMFExploreSectionTypePictureOfTheDay];

    //Sort by date
    [existingSections sortWithOptions:NSSortStable
                      usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [existingSections wmf_arrayByTrimmingToLength:max];
}

- (nullable WMFExploreSection*)continueReadingSection {
    NSDate* resignActiveDate             = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    BOOL const shouldShowContinueReading =
        FBTweakValue(@"Explore", @"Continue Reading", @"Always Show", NO) ||
        fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    //Only return if
    if (shouldShowContinueReading) {
        NSURL* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleURL];
        if (lastRead) {
            return [WMFExploreSection continueReadingSectionWithArticleURL:lastRead];
        }
    }
    return nil;
}

- (nullable WMFExploreSection*)existingContinueReadingSection {
    return [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypeContinueReading) {
            return YES;
        }
        return NO;
    }];
}

- (nullable WMFExploreSection*)existingSectionForArticleURL:(NSURL*)articleURL {
    return [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if ([obj.articleURL isEqual:articleURL]) {
            return YES;
        }
        return NO;
    }];
}

- (NSArray<WMFExploreSection*>*)historyAndSavedPageSections {
    NSMutableArray<WMFExploreSection*>* sections = [NSMutableArray array];

    NSUInteger max = FBTweakValue(@"Explore", @"Sections", @"Max number of history/saved", [WMFExploreSection maxNumberOfSectionsForType:WMFExploreSectionTypeSaved] + [WMFExploreSection maxNumberOfSectionsForType:WMFExploreSectionTypeHistory]);

    NSArray<WMFExploreSection*>* saved   = [self sectionsFromSavedEntriesExcludingExistingTitlesInSections:nil maxLength:max];
    NSArray<WMFExploreSection*>* history = [self sectionsFromHistoryEntriesExcludingExistingTitlesInSections:saved maxLength:max];

    [sections addObjectsFromArray:saved];
    [sections addObjectsFromArray:history];

    //Sort by date
    [sections sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [sections wmf_arrayByTrimmingToLength:max];
}

- (NSArray<WMFExploreSection*>*)sectionsFromHistoryEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFExploreSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<NSURL*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFExploreSection new], articleURL)];

    NSArray<MWKHistoryEntry*>* entries = [self.historyPages.entries bk_select:^BOOL (MWKHistoryEntry* obj) {
        return obj.titleWasSignificantlyViewed;
    }];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self.blackList articleURLIsBlackListed:obj.url];
    }];

    entries = [entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self urlIsForMainArticle:obj.url] || [existingTitles containsObject:obj.url];
    }];

    return [[entries bk_map:^id (MWKHistoryEntry* obj) {
        return [WMFExploreSection historySectionWithHistoryEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

- (NSArray<WMFExploreSection*>*)sectionsFromSavedEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFExploreSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<NSURL*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFExploreSection new], articleURL)];

    NSArray<MWKHistoryEntry*>* entries = [self.savedPages.entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self.blackList articleURLIsBlackListed:obj.url];
    }];

    entries = [entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self urlIsForMainArticle:obj.url] || [existingTitles containsObject:obj.url];
    }];

    return [[entries bk_map:^id (MWKSavedPageEntry* obj) {
        return [WMFExploreSection savedSectionWithSavedPageEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

#pragma mark - WMFLocationManagerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didChangeEnabledState:(BOOL)enabled {
    if (!enabled) {
        [self updateSections:
         [self.sections filteredArrayUsingPredicate:
          [NSPredicate predicateWithBlock:^BOOL (WMFExploreSection* _Nonnull evaluatedObject,
                                                 NSDictionary < NSString*, id > * _Nullable _) {
            return evaluatedObject.type != WMFExploreSectionTypeNearby;
        }]]];
    }
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    if (!location) {
        return;
    }
    if ([[NSDate date] timeIntervalSinceDate:[location timestamp]] > 60 * 5) {
        //We don't want old cached values - fresh data please!
        return;
    }
    [self.locationManager stopMonitoringLocation];
    [self insertNearbySectionWithLocationIfNeeded:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
    WMF_TECH_DEBT_TODO(disable heading updates for this location manager);
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
    if ([WMFLocationManager isDeniedOrDisabled]) {
        [self removeNearbySection];
        [self.locationManager stopMonitoringLocation];
        return;
    }

    if (![error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorLocationUnknown) {
        //TODO: anything we need to handle here?
    }
}

#pragma mark - Persistance

+ (NSDictionary*)encodingBehaviorsByPropertyKey {
    NSMutableDictionary* behaviors = [[super encodingBehaviorsByPropertyKey] mutableCopy];

    #define WMFExploreSectionSchemaKey(key) WMF_SAFE_KEYPATH([WMFExploreSectionSchema new], key)

    behaviors[WMFExploreSectionSchemaKey(siteURL)]       = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(savedPages)]      = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(historyPages)]    = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(delegate)]        = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(locationManager)] = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(blackList)]       = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(fileURL)]         = @(MTLModelEncodingBehaviorExcluded);
    behaviors[WMFExploreSectionSchemaKey(saveQueue)]       = @(MTLModelEncodingBehaviorExcluded);

    return behaviors;
}

- (AnyPromise*)save {
    /*
       NOTE: until this class is made immutable, it cannot safely be passed between threads.
     */
    WMFExploreSectionSchema* backgroundCopy = [self copy];

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        dispatch_async(self.saveQueue, ^{
            NSError* error;
            if (![[NSFileManager defaultManager] createDirectoryAtURL:[self.fileURL URLByDeletingLastPathComponent]
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&error]) {
                DDLogError(@"Failed to save sections to disk: %@", error);
                resolve(error);
                return;
            }

            NSMutableData* result = [NSMutableData data];
            NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:result];

            @try {
                [archiver encodeObject:backgroundCopy forKey:NSKeyedArchiveRootObjectKey];
                [archiver finishEncoding];
                [result writeToURL:self.fileURL
                           options:NSDataWritingAtomic
                             error:&error];
            } @catch (NSException* exception) {
                error = [NSError errorWithDomain:NSInvalidArchiveOperationException
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: exception.name,
                                                   NSLocalizedFailureReasonErrorKey: exception.reason}];
            }

            NSAssert(!error, @"Failed to save sections: %@", error);
            if (error) {
                DDLogError(@"Failed to save sections to disk: %@", error);
            }
            resolve(error);
        });
    }];
}

+ (NSURL*)defaultSchemaURL {
    static NSString* const WMFExploreSectionsFilePath = @"WMFHomeSections.plist";
    NSString* documents                               = documentsDirectory();
    NSString* path                                    = [documents stringByAppendingPathComponent:WMFExploreSectionsFilePath];
    NSURL* url                                        = [NSURL fileURLWithPath:path];
    return url;
}

+ (instancetype)schemaFromFileAtURL:(NSURL*)fileURL {
    //Need to map old class names
    [NSKeyedUnarchiver setClass:[WMFExploreSectionSchema class] forClassName:@"WMFHomeSectionSchema"];
    [NSKeyedUnarchiver setClass:[WMFExploreSection class] forClassName:@"WMFHomeSection"];
    NSError* error;
    NSData* data = [[NSData alloc] initWithContentsOfURL:fileURL options:0 error:&error];
    if (!data) {
        NSAssert([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileReadNoSuchFileError,
                 @"Unexpected error reading schema data: %@", error);
        return nil;
    }
    WMFExploreSectionSchema* schema;

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        schema = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];
    } else {
        @try {
            schema = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        } @catch (NSException* exception) {
            error = [NSError errorWithDomain:NSInvalidArchiveOperationException
                                        code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: exception.name,
                                               NSLocalizedFailureReasonErrorKey: exception.reason}];
        }
    }
    NSAssert(schema, @"Failed to unarchive schema: %@", error);
    return schema;
}

@end

NS_ASSUME_NONNULL_END
