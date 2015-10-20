
#import "WMFHomeSectionSchema.h"
#import "MWKSite.h"
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#import "MWKHistoryList.h"
#import "WMFHomeSection.h"
#import "Wikipedia-Swift.h"
#import "NSDate-Utilities.h"
#import "WMFLocationManager.h"

@import Tweaks;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const WMFMaximumNumberOfNonStaticSections = 20;

static NSTimeInterval const WMFHomeMinimumAutomaticReloadTime      = 600.0; //10 minutes
static NSTimeInterval const WMFTimeBeforeDisplayingLastReadArticle = 24 * 60 * 60; //24 hours

static CLLocationDistance const WMFMinimumDistanceBeforeUpdatingNearby = 500.0;

static NSString* const WMFHomeSectionsFileName      = @"WMFHomeSections";
static NSString* const WMFHomeSectionsFileExtension = @"plist";



@interface WMFHomeSectionSchema ()<WMFLocationManagerDelegate>

@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readwrite) MWKHistoryList* historyPages;

@property (nonatomic, strong) WMFLocationManager* locationManager;


/**
 *  When the location update was requested.
 *  We need this to properly timestamp the section.
 *  We don't want the Nearby section to always have a later date
 *  than every other section causing it to always bubble to the top
 *  just because it is the only section position that is updated async
 */
@property (nonatomic, strong, readwrite) NSDate* locationRequestStarted;

@property (nonatomic, strong, readwrite) NSDate* lastUpdatedAt;

@property (nonatomic, strong, readwrite) NSArray<WMFHomeSection*>* sections;

@end


@implementation WMFHomeSectionSchema

#pragma mark - Setup

+ (instancetype)schemaWithSavedPages:(MWKSavedPageList*)savedPages history:(MWKHistoryList*)history {
    NSParameterAssert(savedPages);
    NSParameterAssert(history);

    WMFHomeSectionSchema* schema = [self loadSchemaFromDisk];

    if (schema) {
        schema.savedPages   = savedPages;
        schema.historyPages = history;
    } else {
        schema = [[WMFHomeSectionSchema alloc] initWithSavedPages:savedPages history:history];
    }

    return schema;
}

- (instancetype)initWithSavedPages:(MWKSavedPageList*)savedPages history:(MWKHistoryList*)history {
    NSParameterAssert(savedPages);
    NSParameterAssert(history);
    self = [super init];
    if (self) {
        self.savedPages   = savedPages;
        self.historyPages = history;
        [self reset];
    }
    return self;
}

- (void)reset {
    NSMutableArray* startingSchema = [[WMFHomeSectionSchema startingSchema] mutableCopy];
    WMFHomeSection* saved          = [[self sectionsFromSavedEntriesExcludingExistingTitlesInSections:nil maxLength:1] firstObject];
    WMFHomeSection* recent         = [[self sectionsFromHistoryEntriesExcludingExistingTitlesInSections:saved ? @[saved] : nil maxLength:1] firstObject];
    if (recent) {
        [startingSchema addObject:recent];
    }
    if (saved) {
        [startingSchema addObject:saved];
    }

    [self updateSections:startingSchema];
}

+ (NSArray*)startingSchema {
    return @[[WMFHomeSection todaySection],
             [WMFHomeSection nearbySectionWithLocation:nil date:nil],
             [WMFHomeSection randomSection]];
}

#pragma mark - Location

- (WMFLocationManager*)locationManager {
    if (_locationManager == nil) {
        _locationManager          = [[WMFLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

#pragma mark - Sections

- (void)updateSections:(NSArray*)sections {
    self.sections = [sections sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult (WMFHomeSection* _Nonnull obj1, WMFHomeSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];
    [self.delegate sectionSchemaDidUpdateSections:self];
    [WMFHomeSectionSchema saveSchemaToDisk:self];
}

#pragma mark - Update

- (void)update {
    [self update:NO];
}

- (void)update:(BOOL)force {
    //Check Tweak
    if (!FBTweakValue(@"Home", @"General", @"Always update on launch", NO)) {
        //Check force flag and minimum relaod time
        if (!force && [[NSDate date] timeIntervalSinceDate:self.lastUpdatedAt] < WMFHomeMinimumAutomaticReloadTime) {
            return;
        }
    }

    //Start updating the location
    [self.locationManager startMonitoringLocation];
    self.locationRequestStarted = [NSDate date];

    //Get updated static sections
    NSMutableArray<WMFHomeSection*>* sections = [[self staticSections] mutableCopy];

    //Add Saved and History
    NSArray<WMFHomeSection*>* recent = [self historyAndSavedPageSections];
    if ([recent count] > 0) {
        [sections addObjectsFromArray:recent];
    }

    self.lastUpdatedAt = [NSDate date];
    [self updateSections:sections];
}

- (void)updateNearbySectionWithLocation:(CLLocation*)location {
    NSParameterAssert(location);

    WMFHomeSection* oldNearby = [self nearbySection];

    //Check Tweak
    if (!FBTweakValue(@"Home", @"Nearby", @"Always update on launch", NO)) {
        //Check didtance to old location
        if (oldNearby.location && [location distanceFromLocation:oldNearby.location] < WMFMinimumDistanceBeforeUpdatingNearby) {
            return;
        }
    }

    NSMutableArray<WMFHomeSection*>* sections = [self.sections mutableCopy];
    [sections bk_performReject:^BOOL (WMFHomeSection* obj) {
        return obj.type == WMFHomeSectionTypeNearby;
    }];

    [sections addObject:[self nearbySectionWithLocation:location]];

    [self updateSections:sections];
}

#pragma mmrk - Create Schema Items

- (NSArray*)staticSections {
    NSMutableArray<WMFHomeSection*>* sections = [NSMutableArray array];

    //Order is important here because dates may be created and we
    //always want the order to be [continue, today, random, nearby]
    //if all are created at the "same" time

    //Add nearby
    WMFHomeSection* nearby = [self nearbySection];
    if (nearby) {
        [sections addObject:nearby];
    }

    //Add Random
    WMFHomeSection* random = [self randomSection];
    if (random) {
        [sections addObject:random];
    }

    //Add today
    WMFHomeSection* today = [self todaySection];
    if (today) {
        [sections addObject:today];
    }

    //Add the last read item
    WMFHomeSection* continueReading = [self continueReadingSection];
    if (continueReading) {
        [sections addObject:continueReading];
    }

    return sections;
}

- (WMFHomeSection*)randomSection {
    WMFHomeSection* random = nil;

    MWKHistoryEntry* lastEntry = [self.historyPages.entries firstObject];

    if (![lastEntry.date isThisWeek]) {
        random = [self.sections bk_match:^BOOL (WMFHomeSection* obj) {
            if (obj.type == WMFHomeSectionTypeRandom) {
                return YES;
            }
            return NO;
        }];
    }

    //Always return a random section
    if (!random) {
        random = [WMFHomeSection randomSection];
    }

    return random;
}

- (WMFHomeSection*)nearbySectionWithLocation:(CLLocation*)location {
    return [WMFHomeSection nearbySectionWithLocation:location date:self.locationRequestStarted];
}

- (WMFHomeSection*)nearbySection {
    WMFHomeSection* nearby = [self.sections bk_match:^BOOL (WMFHomeSection* obj) {
        if (obj.type == WMFHomeSectionTypeNearby) {
            return YES;
        }
        return NO;
    }];

    return nearby;
}

- (WMFHomeSection*)todaySection {
    WMFHomeSection* today = [self.sections bk_match:^BOOL (WMFHomeSection* obj) {
        if (obj.type == WMFHomeSectionTypeToday) {
            return YES;
        }
        return NO;
    }];

    //If it's a new day and we havent created a new today section, create it now
    if (!today || ![today.dateCreated isToday]) {
        today = [WMFHomeSection todaySection];
    }

    return today;
}

- (WMFHomeSection*)continueReadingSection {
    NSDate* resignActiveDate             = [[NSUserDefaults standardUserDefaults] wmf_appResignActiveDate];
    BOOL const shouldShowContinueReading =
        FBTweakValue(@"Home", @"Continue Reading", @"Always Show", NO) ||
        fabs([resignActiveDate timeIntervalSinceNow]) >= WMFTimeBeforeDisplayingLastReadArticle;

    //Only return if
    if (shouldShowContinueReading) {
        MWKTitle* lastRead = [self.historyPages mostRecentEntry].title;
        if (lastRead) {
            return [WMFHomeSection continueReadingSectionWithTitle:lastRead];
        }
    }
    return nil;
}

- (NSArray<WMFHomeSection*>*)historyAndSavedPageSections {
    NSMutableArray<WMFHomeSection*>* sections = [NSMutableArray array];

    NSArray<WMFHomeSection*>* saved   = [self sectionsFromSavedEntriesExcludingExistingTitlesInSections:nil maxLength:WMFMaximumNumberOfNonStaticSections];
    NSArray<WMFHomeSection*>* history = [self sectionsFromHistoryEntriesExcludingExistingTitlesInSections:saved maxLength:WMFMaximumNumberOfNonStaticSections];

    [sections addObjectsFromArray:saved];
    [sections addObjectsFromArray:history];

    //Sort by date
    [sections sortWithOptions:NSSortStable | NSSortConcurrent usingComparator:^NSComparisonResult (WMFHomeSection* _Nonnull obj1, WMFHomeSection* _Nonnull obj2) {
        return -[obj1.dateCreated compare:obj2.dateCreated];
    }];

    return [sections wmf_arrayByTrimmingToLength:WMFMaximumNumberOfNonStaticSections];
}

- (NSArray<WMFHomeSection*>*)sectionsFromHistoryEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFHomeSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<MWKTitle*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFHomeSection new], title)];

    NSArray<MWKHistoryEntry*>* entries = [self.historyPages.entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [existingTitles containsObject:obj.title];
    }];

    return [[entries bk_map:^id (MWKHistoryEntry* obj) {
        return [WMFHomeSection historySectionWithHistoryEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

- (NSArray<WMFHomeSection*>*)sectionsFromSavedEntriesExcludingExistingTitlesInSections:(nullable NSArray<WMFHomeSection*>*)existingSections maxLength:(NSUInteger)maxLength {
    NSArray<MWKTitle*>* existingTitles = [existingSections valueForKeyPath:WMF_SAFE_KEYPATH([WMFHomeSection new], title)];

    NSArray<MWKSavedPageEntry*>* entries = [self.savedPages.entries wmf_arrayByTrimmingToLength:maxLength + [existingSections count]];

    entries = [entries bk_reject:^BOOL (MWKHistoryEntry* obj) {
        return [existingTitles containsObject:obj.title];
    }];

    return [[entries bk_map:^id (MWKSavedPageEntry* obj) {
        return [WMFHomeSection savedSectionWithSavedPageEntry:obj];
    }] wmf_arrayByTrimmingToLength:maxLength];
}

#pragma mark - WMFLocationManagerDelegate

- (void)nearbyController:(WMFLocationManager*)controller didUpdateLocation:(CLLocation*)location {
    [controller stopMonitoringLocation];
    [self updateNearbySectionWithLocation:location];
}

- (void)nearbyController:(WMFLocationManager*)controller didUpdateHeading:(CLHeading*)heading {
}

- (void)nearbyController:(WMFLocationManager*)controller didReceiveError:(NSError*)error {
}

#pragma mark - Persistance

+ (NSDictionary*)encodingBehaviorsByPropertyKey {
    NSMutableDictionary* behaviors = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"savedPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"historyPages"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"delegate"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"locationManager"];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:@"locationRequestStarted"];
    return behaviors;
}

+ (NSURL*)schemaFileURL {
    return [NSURL fileURLWithPath:[[documentsDirectory() stringByAppendingPathComponent:WMFHomeSectionsFileName] stringByAppendingPathExtension:WMFHomeSectionsFileExtension]];
}

+ (void)saveSchemaToDisk:(WMFHomeSectionSchema*)schema {
    dispatchOnBackgroundQueue(^{
        if (![NSKeyedArchiver archiveRootObject:schema toFile:[[self schemaFileURL] path]]) {
            //TODO: not sure what to do with an error here
            DDLogError(@"Failed to save sections to disk!");
        }
    });
}

+ (WMFHomeSectionSchema*)loadSchemaFromDisk {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[self schemaFileURL] path]];
}

@end

NS_ASSUME_NONNULL_END
