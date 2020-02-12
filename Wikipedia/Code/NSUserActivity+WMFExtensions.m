#import <WMF/NSUserActivity+WMFExtensions.h>
#import <WMF/WMF-Swift.h>

@import CoreSpotlight;
@import MobileCoreServices;

NSString *const WMFNavigateToActivityNotification = @"WMFNavigateToActivityNotification";

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
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"WMFArticleURL"]) {
            NSString *articleURLString = item.value;
            articleURL = [NSURL URLWithString:articleURLString];
            break;
        }
    }
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Places"];
    activity.webpageURL = articleURL;
    return activity;
}

+ (instancetype)wmf_exploreViewActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Explore"];
    return activity;
}

+ (instancetype)wmf_savedPagesViewActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"Saved"];
    return activity;
}

+ (instancetype)wmf_recentViewActivity {
    NSUserActivity *activity = [self wmf_pageActivityWithName:@"History"];
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
    } else if ([url.host isEqualToString:@"history"]) {
        return [self wmf_recentViewActivity];
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
        } else if ([page isEqualToString:@"History"]) {
            return WMFUserActivityTypeHistory;
        } else if ([page isEqualToString:@"Search"]) {
            return WMFUserActivityTypeSearch;
        } else if ([page isEqualToString:@"AppearanceSettings"]) {
            return WMFUserActivityTypeAppearanceSettings;
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
        case WMFUserActivityTypeHistory:
            host = @"history";
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
        case WMFUserActivityTypeExplore:
        default:
            host = @"explore";
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
