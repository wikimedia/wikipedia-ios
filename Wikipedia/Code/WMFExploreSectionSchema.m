
#import "WMFExploreSectionSchema.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"
#import "WMFExploreSection.h"
#import "Wikipedia-Swift.h"
#import "NSDate+Utilities.h"
#import "WMFLocationManager.h"
#import "WMFAssetsFile.h"
#import "WMFRelatedSectionBlackList.h"

@import Tweaks;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const WMFMaximumNumberOfHistoryAndSavedSections = 20;
static NSUInteger const WMFMaximumNumberOfFeaturedSections        = 10;

static NSTimeInterval const WMFHomeMinimumAutomaticReloadTime      = 600.0; //10 minutes
static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 24 * 60 * 60; //24 hours
static NSTimeInterval const WMFTimeBeforeRefreshingRandom          = 60 * 60 * 24 * 7; //7 days


static CLLocationDistance const WMFMinimumDistanceBeforeUpdatingNearby = 500.0;

static NSString* const WMFExploreSectionsFileName      = @"WMFHomeSections";
static NSString* const WMFExploreSectionsFileExtension = @"plist";



@interface WMFExploreSectionSchema ()<WMFLocationManagerDelegate>

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readwrite) MWKHistoryList* historyPages;
@property (nonatomic, strong, readwrite) WMFRelatedSectionBlackList* blackList;

@property (nonatomic, strong) WMFLocationManager* locationManager;

@property (nonatomic, strong, readwrite) WMFAssetsFile* mainPages;

@property (nonatomic, strong, readwrite, nullable) NSDate* lastUpdatedAt;

@property (nonatomic, strong, readwrite) NSArray<WMFExploreSection*>* sections;

@end


@implementation WMFExploreSectionSchema

- (NSString*)description {
    // HAX: prevent this from logging all its properties in its description, as this causes recursion to
    // WMFLocationManager.description
    return [NSString stringWithFormat:@"<%@: %p>", [self class], self];
}

#pragma mark - Setup

+ (instancetype)schemaWithSite:(MWKSite*)site savedPages:(MWKSavedPageList*)savedPages history:(MWKHistoryList*)history blackList:(WMFRelatedSectionBlackList*)blackList {
    NSParameterAssert(site);
    NSParameterAssert(savedPages);
    NSParameterAssert(history);
    NSParameterAssert(blackList);

    WMFExploreSectionSchema* schema = [self loadSchemaFromDisk];

    if (schema) {
        schema.site         = site;
        schema.savedPages   = savedPages;
        schema.historyPages = history;
        schema.blackList    = blackList;
    } else {
        schema = [[WMFExploreSectionSchema alloc] initWithSite:site savedPages:savedPages history:history blackList:blackList];
    }

    return schema;
}

- (instancetype)initWithSite:(MWKSite*)site
                  savedPages:(MWKSavedPageList*)savedPages
                     history:(MWKHistoryList*)history
                   blackList:(WMFRelatedSectionBlackList*)blackList {
    NSParameterAssert(site);
    NSParameterAssert(savedPages);
    NSParameterAssert(history);
    NSParameterAssert(blackList);
    self = [super init];
    if (self) {
        self.site         = site;
        self.savedPages   = savedPages;
        self.historyPages = history;
        self.blackList    = blackList;
        [self reset];
    }
    return self;
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
 *  Reset the feed to its initial set, containing a specific array of items depending on the current site.
 *
 *  Inserts featured section as well as related sections from saved and/or history to the @c startingSchema.
 *
 *  @see startingSchema
 */
- (void)reset {
    NSMutableArray<WMFExploreSection*>* startingSchema = [[WMFExploreSectionSchema startingSchema] mutableCopy];

    [startingSchema wmf_safeAddObject:[WMFExploreSection featuredArticleSectionWithSiteIfSupported:self.site]];

    WMFExploreSection* saved =
        [[self sectionsFromSavedEntriesExcludingExistingTitlesInSections:nil maxLength:1] firstObject];

    WMFExploreSection* recent =
        [[self sectionsFromHistoryEntriesExcludingExistingTitlesInSections:saved ? @[saved] : nil maxLength:1] firstObject];

    [startingSchema wmf_safeAddObject:recent];
    [startingSchema wmf_safeAddObject:saved];

    self.lastUpdatedAt = nil;
    [self updateSections:startingSchema];
}

/**
 *  Sections used to "seed" a user's "feed" with an initial set of content.
 *
 *  Omits certain sections which are not guaranteed to be available (e.g. featured articles & nearby).
 *
 *  @return An array of sections that can be used to start the "feed" from scratch.
 */
+ (NSArray<WMFExploreSection*>*)startingSchema {
    return @[[WMFExploreSection mainPageSection],
             [WMFExploreSection pictureOfTheDaySection],
             [WMFExploreSection randomSection]];
}

#pragma mark - Location

- (WMFLocationManager*)locationManager {
    if (_locationManager == nil) {
        _locationManager          = [[WMFLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - Main Article

/*
 * This is required so we don't show items related to main pages in the feed.
 * Ideally, we would pull this info from a service - but for now this is the easiest way to do it.
 * Note: we can get main pages individually for each site via the API, but not in an aggregate call.
 */
- (WMFAssetsFile*)mainPages {
    if (!_mainPages) {
        _mainPages = [[WMFAssetsFile alloc] initWithFileType:WMFAssetsFileTypeMainPages];
    }

    return _mainPages;
}

- (MWKTitle*)mainArticleTitleForSite:(MWKSite*)site {
    if (!site.language) {
        return nil;
    }
    NSString* titleText = self.mainPages.dictionary[site.language];
    if (!titleText) {
        return nil;
    }
    return [site titleWithString:titleText];
}

- (BOOL)titleIsForMainArticle:(MWKTitle*)title {
    MWKTitle* mainArticleTitle = [self mainArticleTitleForSite:title.site];
    return ([title.text isEqualToString:mainArticleTitle.text]);
}

#pragma mark - Sections

- (void)updateSections:(NSArray<WMFExploreSection*>*)sections {
    self.sections = [sections sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    [self.delegate sectionSchemaDidUpdateSections:self];
    [WMFExploreSectionSchema saveSchemaToDisk:self];
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
    [WMFExploreSectionSchema saveSchemaToDisk:self];
}

#pragma mark - Update

- (void)update {
    [self update:NO];
}

- (BOOL)update:(BOOL)force {
    [self.locationManager restartLocationMonitoring];

    if (!FBTweakValue(@"Explore", @"General", @"Always update on launch", NO)
        && !force
        && self.lastUpdatedAt
        && [[NSDate date] timeIntervalSinceDate:self.lastUpdatedAt] < WMFHomeMinimumAutomaticReloadTime) {
        return NO;
    }

    //Get updated static sections
    NSMutableArray<WMFExploreSection*>* sections = [[self staticSections] mutableCopy];

    //Add featured articles
    [sections addObjectsFromArray:[self featuredSections]];

    //Add Saved and History
    NSArray<WMFExploreSection*>* recent = [self historyAndSavedPageSections];
    if ([recent count] > 0) {
        [sections addObjectsFromArray:recent];
    }

    self.lastUpdatedAt = [NSDate date];
    [self updateSections:sections];
    return YES;
}

- (void)insertNearbySectionWithLocationIfNeeded:(CLLocation*)location {
    NSParameterAssert(location);

    WMFExploreSection* oldNearby = [self existingNearbySection];

    // Check distance to old location
    if (oldNearby.location && [location distanceFromLocation:oldNearby.location] < WMFMinimumDistanceBeforeUpdatingNearby) {
        return;
    }

    // Check if already updated today
    if (oldNearby.location && [oldNearby.dateCreated isToday]) {
        return;
    }

    NSMutableArray<WMFExploreSection*>* sections = [self.sections mutableCopy];
    [sections bk_performReject:^BOOL (WMFExploreSection* obj) {
        return obj.type == WMFExploreSectionTypeNearby;
    }];

    [sections wmf_safeAddObject:[self nearbySectionWithLocation:location]];

    [self updateSections:sections];
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
    [[blackList.entries wmf_mapAndRejectNil:^id (MWKTitle* obj) {
        return [self existingSectionForTitle:obj];
    }] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WMFExploreSection* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        [self removeSection:obj];
    }];
}

#pragma mmrk - Create Schema Items

/**
 *  Sections which should always be present in the "feed" (i.e. everything that isn't site specific).
 *
 *  @return An array of all existing site-independent sections.
 */
- (NSArray<WMFExploreSection*>*)staticSections {
    NSMutableArray<WMFExploreSection*>* sections = [NSMutableArray array];

    [sections wmf_safeAddObject:[self existingNearbySection]];
    [sections wmf_safeAddObject:[self randomSection]];
    [sections addObject:[self mainPageSection]];
    [sections addObject:[self picOfTheDaySection]];
    [sections wmf_safeAddObject:[self continueReadingSection]];

    return sections;
}

- (WMFExploreSection*)randomSection {
    WMFExploreSection* random = [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypeRandom) {
            return YES;
        }
        return NO;
    }];
    ;
    MWKHistoryEntry* lastEntry = [self.historyPages.entries firstObject];
    if (lastEntry && [[NSDate date] timeIntervalSinceDate:lastEntry.date] > WMFTimeBeforeRefreshingRandom) {
        random = [WMFExploreSection randomSection];
    }

    //Always return a random section
    if (!random) {
        random = [WMFExploreSection randomSection];
    }

    return random;
}

- (nullable WMFExploreSection*)existingNearbySection {
    WMFExploreSection* nearby = [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if (obj.type == WMFExploreSectionTypeNearby && obj.location) {
            return YES;
        }
        return NO;
    }];

    return nearby;
}

#pragma mark - Daily Sections

- (NSArray<WMFExploreSection*>*)featuredSections {
    NSArray* existingFeaturedArticleSections = [self.sections bk_select:^BOOL (WMFExploreSection* obj) {
        return obj.type == WMFExploreSectionTypeFeaturedArticle;
    }];

    //Don't add new ones if we aren't in english
    NSMutableArray* featured = [existingFeaturedArticleSections mutableCopy];

    WMFExploreSection* today = [featured bk_match:^BOOL (WMFExploreSection* obj) {
        NSAssert(obj.type == WMFExploreSectionTypeFeaturedArticle,
                 @"List should only contain featured sections, got %@", featured);
        return [obj.dateCreated isToday];
    }];

    if (!today) {
        [featured wmf_safeAddObject:[WMFExploreSection featuredArticleSectionWithSiteIfSupported:self.site]];
    }

    NSUInteger max = FBTweakValue(@"Explore", @"Sections", @"Max number of featured", WMFMaximumNumberOfFeaturedSections);

    //Sort by date
    [featured sortWithOptions:NSSortStable
              usingComparator:^NSComparisonResult (WMFExploreSection* _Nonnull obj1, WMFExploreSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [featured wmf_arrayByTrimmingToLength:max];
}

- (WMFExploreSection*)getOrCreateStaticTodaySectionOfType:(WMFExploreSectionType)type {
    WMFExploreSection* existingSection = [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if (obj.type == type) {
            return YES;
        }
        return NO;
    }];

    //If it's a new day and we havent created a new main page section, create it now
    if ([existingSection.dateCreated isToday]) {
        return existingSection;
    }

    switch (type) {
        case WMFExploreSectionTypeMainPage:
            return [WMFExploreSection mainPageSection];
        case WMFExploreSectionTypePictureOfTheDay:
            return [WMFExploreSection pictureOfTheDaySection];

        default:
            NSAssert(NO, @"Cannot create static 'today' section of type %ld", type);
            return nil;
    }
}

- (WMFExploreSection*)nearbySectionWithLocation:(nullable CLLocation*)location {
    if ([WMFLocationManager isDeniedOrDisabled]) {
        return nil;
    }
    return [WMFExploreSection nearbySectionWithLocation:location];
}

- (WMFExploreSection*)mainPageSection {
    return [self getOrCreateStaticTodaySectionOfType:WMFExploreSectionTypeMainPage];
}

- (WMFExploreSection*)picOfTheDaySection {
    return [self getOrCreateStaticTodaySectionOfType:WMFExploreSectionTypePictureOfTheDay];
}

- (nullable WMFExploreSection*)continueReadingSection {
    NSDate* resignActiveDate             = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    BOOL const shouldShowContinueReading =
        FBTweakValue(@"Explore", @"Continue Reading", @"Always Show", NO) ||
        fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    //Only return if
    if (shouldShowContinueReading) {
        MWKTitle* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleTitle];
        if (lastRead) {
            return [WMFExploreSection continueReadingSectionWithTitle:lastRead];
        }
    }
    return nil;
}

- (nullable WMFExploreSection*)existingSectionForTitle:(MWKTitle*)title {
    return [self.sections bk_match:^BOOL (WMFExploreSection* obj) {
        if ([obj.title isEqualToTitle:title]) {
            return YES;
        }
        return NO;
    }];
}

- (NSArray<WMFExploreSection*>*)historyAndSavedPageSections {
    NSMutableArray<WMFExploreSection*>* sections = [NSMutableArray array];

    NSUInteger max = FBTweakValue(@"Explore", @"Sections", @"Max number of history/saved", WMFMaximumNumberOfHistoryAndSavedSections);

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
    NSArray<MWKTitle*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFExploreSection new], title)];

    NSArray<MWKHistoryEntry*>* entries = [self.historyPages.entries bk_select:^BOOL (MWKHistoryEntry* obj) {
        return obj.titleWasSignificantlyViewed;
    }];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self.blackList titleIsBlackListed:obj.title];
    }];

    entries = [entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self titleIsForMainArticle:obj.title] || [existingTitles containsObject:obj.title];
    }];

    return [[entries bk_map:^id (MWKHistoryEntry* obj) {
        return [WMFExploreSection historySectionWithHistoryEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

- (NSArray<WMFExploreSection*>*)sectionsFromSavedEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFExploreSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<MWKTitle*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFExploreSection new], title)];

    NSArray<MWKHistoryEntry*>* entries = [self.savedPages.entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self.blackList titleIsBlackListed:obj.title];
    }];

    entries = [entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [self titleIsForMainArticle:obj.title] || [existingTitles containsObject:obj.title];
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
    [self insertNearbySectionWithLocationIfNeeded:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
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
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"site"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"savedPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"historyPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"mainPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"delegate"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"locationManager"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"locationRequestStarted"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"blackList"];

    return behaviors;
}

+ (NSURL*)schemaFileURL {
    return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFExploreSectionsFileName] stringByAppendingPathExtension:WMFExploreSectionsFileExtension]];
}

+ (void)saveSchemaToDisk:(WMFExploreSectionSchema*)schema {
    dispatchOnBackgroundQueue(^{
        if (![NSKeyedArchiver archiveRootObject:schema toFile:[[self schemaFileURL] path]]) {
            //TODO: not sure what to do with an error here
            DDLogError(@"Failed to save sections to disk!");
        }
    });
}

+ (WMFExploreSectionSchema*)loadSchemaFromDisk {
    //Need to map old class names
    [NSKeyedUnarchiver setClass:[WMFExploreSectionSchema class] forClassName:@"WMFHomeSectionSchema"];
    [NSKeyedUnarchiver setClass:[WMFExploreSection class] forClassName:@"WMFHomeSection"];

    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self schemaFileURL] path]];
}

@end

NS_ASSUME_NONNULL_END
