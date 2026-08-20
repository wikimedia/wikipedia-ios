#import <WMF/NSUserActivity+WMFExtensions.h>
#import <WMF/WMF-Swift.h>

@import CoreSpotlight;
@import MobileCoreServices;
@import CoreLocation;

NSString *const WMFNavigateToActivityNotification = @"WMFNavigateToActivityNotification";

NSString *const WMFPlacesActivityLatitudeKey = @"WMFPlacesLatitude";
NSString *const WMFPlacesActivityLongitudeKey = @"WMFPlacesLongitude";
NSString *const WMFPlacesActivityLocationNameKey = @"WMFPlacesLocationName";

// Query item names accepted for the latitude of a `wikipedia://places` deep link.
static NSArray<NSString *> *WMFPlacesLatitudeQueryItemNames(void) {
    return @[@"latitude", @"lat"];
}

// Query item names accepted for the longitude of a `wikipedia://places` deep link.
static NSArray<NSString *> *WMFPlacesLongitudeQueryItemNames(void) {
    return @[@"longitude", @"lon", @"lng", @"long"];
}

// Query item names accepted for the display name of a `wikipedia://places` deep link.
static NSArray<NSString *> *WMFPlacesNameQueryItemNames(void) {
    return @[@"name", @"title"];
}

// Parses a coordinate component in a locale independent way. Deep link values always use a
// dot as the decimal separator, so parsing with the user's locale (which may use a comma)
// would silently misread them.
static NSNumber *_Nullable WMFDegreesFromQueryValue(NSString *_Nullable value) {
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }

    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.usesGroupingSeparator = NO;
    });

    return [formatter numberFromString:trimmed];
}

// Use to suppress "User-facing text should use localized string macro" Analyzer warning
// where appropriate.
__attribute__((annotate("returns_localized_nsstring"))) static inline NSString *wmf_localizationNotNeeded(NSString *s) {
    return s;
}

@implementation NSUserActivity (WMFExtensions)

+ (void)wmf_navigateToActivity:(NSUserActivity *)activity {
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFNavigateToActivityNotification object:activity];
}

+ (void)wmf_makeActivityActive:(NSUserActivity *)activity {
    static NSUserActivity *_current = nil;

    if (_current) {
        [_current invalidate];
        _current = nil;
    }

    _current = activity;
    [_current becomeCurrent];
}

+ (instancetype)wmf_activityWithType:(NSString *)type {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:[NSString stringWithFormat:@"org.wikimedia.wikipedia.%@", [type lowercaseString]]];

    activity.eligibleForHandoff = YES;
    activity.eligibleForSearch = YES;
    activity.eligibleForPublicIndexing = YES;
    activity.keywords = [NSSet setWithArray:@[@"Wikipedia", @"Wikimedia", @"Wiki"]];

    return activity;
}

+ (instancetype)wmf_pageActivityWithName:(NSString *)pageName {
    NSUserActivity *activity = [self wmf_activityWithType:[pageName lowercaseString]];
    activity.title = wmf_localizationNotNeeded(pageName);
    activity.userInfo = @{@"WMFPage": pageName};

    NSMutableSet *set = [activity.keywords mutableCopy];
    [set addObjectsFromArray:[pageName componentsSeparatedByString:@" "]];
    activity.keywords = set;

    return activity;
}

+ (instancetype)wmf_contentActivityWithURL:(NSURL *)url {
    NSUserActivity *activity = [self wmf_activityWithType:@"Content"];
    activity.userInfo = @{@"WMFURL": url};
    return activity;
}

+ (instancetype)wmf_placesActivityWithURL:(NSURL *)activityURL {
    NSURLComponents *components = [NSURLComponents componentsWithURL:activityURL resolvingAgainstBaseURL:NO];
    NSURL *articleURL = nil;
    NSString *latitudeValue = nil;
    NSString *longitudeValue = nil;
    NSString *nameValue = nil;

    for (NSURLQueryItem *item in components.queryItems) {
        NSString *name = [item.name lowercaseString];
        if ([item.name isEqualToString:@"WMFArticleURL"]) {
            articleURL = [NSURL URLWithString:item.value];
        } else if (latitudeValue == nil && [WMFPlacesLatitudeQueryItemNames() containsObject:name]) {
            latitudeValue = item.value;
        } else if (longitudeValue == nil && [WMFPlacesLongitudeQueryItemNames() containsObject:name]) {
            longitudeValue = item.value;
        } else if (nameValue == nil && [WMFPlacesNameQueryItemNames() containsObject:name]) {
            nameValue = item.value;
        }
    }

    NSNumber *latitude = WMFDegreesFromQueryValue(latitudeValue);
    NSNumber *longitude = WMFDegreesFromQueryValue(longitudeValue);

    if (latitude != nil && longitude != nil) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        if (CLLocationCoordinate2DIsValid(coordinate)) {
            NSUserActivity *activity = [self wmf_placesActivityWithLatitude:coordinate.latitude longitude:coordinate.longitude name:nameValue];
            activity.webpageURL = articleURL;
            return activity;
        }
    }

    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Places"];
    activity.webpageURL = articleURL;
    return activity;
}

+ (instancetype)wmf_placesActivityWithLatitude:(double)latitude longitude:(double)longitude name:(NSString *)name {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Places"];

    NSMutableDictionary *userInfo = [activity.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
    userInfo[WMFPlacesActivityLatitudeKey] = @(latitude);
    userInfo[WMFPlacesActivityLongitudeKey] = @(longitude);
    if (name.length > 0) {
        userInfo[WMFPlacesActivityLocationNameKey] = name;
    }
    activity.userInfo = userInfo;

    return activity;
}

+ (NSURL *)wmf_placesURLWithLatitude:(double)latitude longitude:(double)longitude name:(NSString *)name {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = @"wikipedia";
    components.host = @"places";

    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithObjects:
                                                                      [NSURLQueryItem queryItemWithName:@"latitude" value:[NSString stringWithFormat:@"%f", latitude]],
                                                                      [NSURLQueryItem queryItemWithName:@"longitude" value:[NSString stringWithFormat:@"%f", longitude]],
                                                                      nil];
    if (name.length > 0) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"name" value:name]];
    }
    components.queryItems = queryItems;

    return components.URL;
}

+ (BOOL)wmf_isExploreFeedEnabled {
    return [NSUserDefaults.standardUserDefaults defaultTabType] == WMFAppDefaultTabTypeExplore;
}

+ (instancetype)wmf_exploreViewActivity {
    if (![self wmf_isExploreFeedEnabled]) {
        return [self wmf_searchViewActivity];
    }
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Explore"];
    return activity;
}

+ (instancetype)wmf_savedPagesViewActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Saved"];
    return activity;
}

+ (instancetype)wmf_activityTabActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Activity"];
    return activity;
}

+ (instancetype)wmf_searchViewActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Search"];
    return activity;
}

+ (instancetype)wmf_settingsViewActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Settings"];
    return activity;
}

+ (instancetype)wmf_appearanceSettingsActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"AppearanceSettings"];
    return activity;
}

+ (instancetype)wmf_languageSettingsActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"LanguageSettings"];
    return activity;
}

+ (nullable instancetype)wmf_activityForWikipediaScheme:(NSURL *)url {
    if (![url.scheme isEqualToString:@"wikipedia"] && ![url.scheme isEqualToString:@"wikipedia-official"]) {
        return nil;
    }

    if ([url.host isEqualToString:@"content"]) {
        return [self wmf_contentActivityWithURL:url];
    } else if ([url.host isEqualToString:@"explore"]) {
        return [self wmf_exploreViewActivity];
    } else if ([url.host isEqualToString:@"places"]) {
        return [self wmf_placesActivityWithURL:url];
    } else if ([url.host isEqualToString:@"saved"]) {
        return [self wmf_savedPagesViewActivity];
    } else if ([url.host isEqualToString:@"activity"]) {
        NSUserActivity *activity = [self wmf_activityTabActivity];
        NSString *collectPrize = [url wmf_valueForQueryKey:@"collectPrize"];
        NSString *join = [url wmf_valueForQueryKey:@"join"];
        NSString *appStoreEvent = [url wmf_valueForQueryKey:@"appStoreEvent"];
        if ([collectPrize isEqualToString:@"true"]) {
            NSMutableDictionary *userInfo = [activity.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
            userInfo[@"collectPrize"] = @YES;
            activity.userInfo = userInfo;
        } else if ([join isEqualToString:@"true"]) {
            NSMutableDictionary *userInfo = [activity.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
            userInfo[@"join"] = @YES;
            activity.userInfo = userInfo;
        } else if ([appStoreEvent isEqualToString:@"true"]) {
            NSMutableDictionary *userInfo = [activity.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
            userInfo[@"appStoreEvent"] = @YES;
            activity.userInfo = userInfo;
        }
        return activity;
    } else if ([url.host isEqualToString:@"search"]) {
        return [self wmf_searchViewActivity];
    } else if ([url.host isEqualToString:@"random"]) {
        return [self wmf_randomArticleActivity];
    } else if ([url wmf_valueForQueryKey:@"search"] != nil) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.scheme = @"https";
        return [self wmf_searchResultsActivitySearchSiteURL:components.URL
                                                 searchTerm:[url wmf_valueForQueryKey:@"search"]];
    } else {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        components.scheme = @"https";
        NSURL *wikipediaURL = components.URL;
        if ([wikipediaURL wmf_isWikiResource]) {
            return [self wmf_articleViewActivityWithURL:wikipediaURL];
        }
    }
    return nil;
}

+ (instancetype)wmf_randomArticleActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Random"];
    return activity;
}

+ (nullable instancetype)wmf_activityForURL:(NSURL *)url {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"https";
    NSURL *wikipediaURL = components.URL;
    if (![wikipediaURL wmf_isWikiResource]) {
        return nil;
    }
    return [self wmf_articleViewActivityWithURL:wikipediaURL];
}

+ (instancetype)wmf_articleViewActivityWithURL:(NSURL *)url {
    NSParameterAssert(url.wmf_title);

    NSUserActivity *activity = [self wmf_activityWithType:@"article"];
    activity.title = url.wmf_title;
    activity.webpageURL = [NSURL wmf_desktopURLForURL:url];

    NSMutableSet *set = [activity.keywords mutableCopy];
    [set addObjectsFromArray:[url.wmf_title componentsSeparatedByString:@" "]];
    activity.keywords = set;
    activity.expirationDate = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * 7];
    activity.contentAttributeSet = url.wmf_searchableItemAttributes;

    return activity;
}

+ (instancetype)wmf_searchResultsActivitySearchSiteURL:(NSURL *)url searchTerm:(NSString *)searchTerm {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.path = @"/w/index.php";
    NSMutableArray *queryItems = [NSMutableArray arrayWithCapacity:3];
    NSURLQueryItem *queryItem = nil;
    if (searchTerm) {
        queryItem = [NSURLQueryItem queryItemWithName:@"search" value:searchTerm];
        if (queryItem) {
            [queryItems addObject:queryItem];
        }
    }
    queryItem = [NSURLQueryItem queryItemWithName:@"title" value:@"Special:Search"];
    if (queryItem) {
        [queryItems addObject:queryItem];
    }

    queryItem = [NSURLQueryItem queryItemWithName:@"fulltext" value:@"1"];
    if (queryItem) {
        [queryItems addObject:queryItem];
    }

    components.queryItems = queryItems;
    url = [components URL];

    NSUserActivity *activity = [self wmf_activityWithType:@"Searchresults"];

    activity.title = [NSString stringWithFormat:@"Search for %@", searchTerm];
    activity.webpageURL = url;

    activity.eligibleForSearch = NO;
    activity.eligibleForPublicIndexing = NO;

    return activity;
}

- (WMFUserActivityType)wmf_type {
    if (self.userInfo[@"WMFPage"] != nil) {
        NSString *page = self.userInfo[@"WMFPage"];
        if ([page isEqualToString:@"Explore"]) {
            return WMFUserActivityTypeExplore;
        } else if ([page isEqualToString:@"Places"]) {
            return WMFUserActivityTypePlaces;
        } else if ([page isEqualToString:@"Saved"]) {
            return WMFUserActivityTypeSavedPages;
        } else if ([page isEqualToString:@"Search"]) {
            return WMFUserActivityTypeSearch;
        } else if ([page isEqualToString:@"AppearanceSettings"]) {
            return WMFUserActivityTypeAppearanceSettings;
        } else if ([page isEqualToString:@"Random"]) {
            return WMFUserActivityTypeRandom;
        } else if ([page isEqualToString:@"Activity"]) {
            return WMFUserActivityTypeActivity;
        } else {
            return WMFUserActivityTypeSettings;
        }
    } else if ([self wmf_contentURL]) {
        return WMFUserActivityTypeContent;
    } else if ([self.activityType isEqualToString:CSQueryContinuationActionType]) {
        return WMFUserActivityTypeSearchResults;
    } else {
        return WMFUserActivityTypeLink;
    }
}

- (nullable NSString *)wmf_searchTerm {
    if (self.wmf_type != WMFUserActivityTypeSearchResults) {
        return nil;
    }

    if ([self.activityType isEqualToString:CSQueryContinuationActionType]) {
        return self.userInfo[CSSearchQueryString];
    } else {
        NSURLComponents *components = [NSURLComponents componentsWithString:self.webpageURL.absoluteString];
        NSArray *queryItems = components.queryItems;
        NSURLQueryItem *item = [queryItems wmf_match:^BOOL(NSURLQueryItem *obj) {
            if ([[obj name] isEqualToString:@"search"]) {
                return YES;
            } else {
                return NO;
            }
        }];
        return [item value];
    }
}

- (NSURL *)wmf_linkURL {
    if (self.userInfo[CSSearchableItemActivityIdentifier] != nil) {
        return [NSURL URLWithString:self.userInfo[CSSearchableItemActivityIdentifier]];
    } else {
        return self.webpageURL;
    }
}

- (NSURL *)wmf_contentURL {
    return self.userInfo[@"WMFURL"];
}

+ (NSURLComponents *)wmf_baseURLComponentsForActivityOfType:(WMFUserActivityType)type {
    NSString *host = nil;
    switch (type) {
        case WMFUserActivityTypeSavedPages:
            host = @"saved";
            break;
        case WMFUserActivityTypeSearchResults:
        case WMFUserActivityTypeSearch:
            host = @"search";
            break;
        case WMFUserActivityTypeSettings:
            host = @"settings";
            break;
        case WMFUserActivityTypeAppearanceSettings:
            host = @"appearancesettings";
            break;
        case WMFUserActivityTypeContent:
            host = @"content";
            break;
        case WMFUserActivityTypePlaces:
            host = @"places";
            break;
        case WMFUserActivityTypeActivity:
            host = @"Activity";
            break;
        case WMFUserActivityTypeRandom:
            host = @"Random";
            break;
        case WMFUserActivityTypeExplore:
        default:
            host = [self wmf_isExploreFeedEnabled] ? @"explore" : @"search";
            break;
    }
    NSURLComponents *components = [NSURLComponents new];
    components.host = host;
    components.scheme = @"wikipedia";
    components.path = @"/";
    return components;
}

+ (NSURL *)wmf_baseURLForActivityOfType:(WMFUserActivityType)type {
    return [self wmf_baseURLComponentsForActivityOfType:type].URL;
}

+ (NSURL *)wmf_URLForActivityOfType:(WMFUserActivityType)type withArticleURL:(NSURL *)articleURL {
    NSURLComponents *components = [self wmf_baseURLComponentsForActivityOfType:type];
    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:@"WMFArticleURL" value:articleURL.absoluteString];
    if (item) {
        components.queryItems = @[item];
    }
    return components.URL;
}

@end
