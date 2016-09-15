#import "NSUserActivity+WMFExtensions.h"
#import <WMFModel/WMFModel-Swift.h>

@import CoreSpotlight;
@import MobileCoreServices;

@implementation NSUserActivity (WMFExtensions)

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
    activity.title = pageName;
    activity.userInfo = @{ @"WMFPage": pageName };

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        NSMutableSet *set = [activity.keywords mutableCopy];
        [set addObjectsFromArray:[pageName componentsSeparatedByString:@" "]];
        activity.keywords = set;
    }

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

+ (instancetype)wmf_activityForWikipediaScheme:(NSURL *)url {
    if (![url.scheme isEqualToString:@"wikipedia"]) {
        return nil;
    }

    if ([url.host isEqualToString:@"explore"]) {
        return [self wmf_exploreViewActivity];
    } else if ([url.host isEqualToString:@"saved"]) {
        return [self wmf_savedPagesViewActivity];
    } else if ([url.host isEqualToString:@"history"]) {
        return [self wmf_recentViewActivity];
    } else if ([url.host isEqualToString:@"topread"]) {
        NSString *timestampString = [url wmf_valueForQueryKey:@"timestamp"];
        long long timestamp = [timestampString longLongValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        NSString *siteURLString = [url wmf_valueForQueryKey:@"siteURL"];
        NSURL *siteURL = [NSURL URLWithString:siteURLString];
        return [self wmf_topReadActivityForSiteURL:siteURL date:date];
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

+ (NSURL *)wmf_URLForActivityOfType:(WMFUserActivityType)type parameters:(NSDictionary *)params {
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
        case WMFUserActivityTypeTopRead:
            host = @"topread";
            break;
        case WMFUserActivityTypeArticle:
            host = @"article";
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
    if (params.count > 0) {
        NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithCapacity:params.count];
        for (NSString *name in params.allKeys) {
            id value = params[name];
            if (!value) {
                continue;
            }
            if (![value isKindOfClass:[NSString class]]) {
                value = [NSString stringWithFormat:@"%@", value]; // really this should check class and use formatters
            }
            NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:name value:value];
            if (!item) {
                continue;
            }
            [queryItems addObject:item];
        }
        components.queryItems = queryItems;
    }
    return components.URL;
}

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle *)article {
    NSParameterAssert(article.url.wmf_title);
    NSParameterAssert(article.displaytitle);

    NSUserActivity *activity = [self wmf_articleViewActivityWithURL:article.url];
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        activity.contentAttributeSet = article.searchableItemAttributes;
    }
    return activity;
}

+ (instancetype)wmf_articleViewActivityWithURL:(NSURL *)url {
    NSParameterAssert(url.wmf_title);

    NSUserActivity *activity = [self wmf_activityWithType:@"article"];
    activity.title = url.wmf_title;
    activity.webpageURL = [NSURL wmf_desktopURLForURL:url];

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        NSMutableSet *set = [activity.keywords mutableCopy];
        [set addObjectsFromArray:[url.wmf_title componentsSeparatedByString:@" "]];
        activity.keywords = set;
        activity.expirationDate = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * 7];
        activity.contentAttributeSet = url.searchableItemAttributes;
    }
    return activity;
}

+ (instancetype)wmf_topReadActivityForSiteURL:(NSURL *)siteURL date:(NSDate *)date {
    NSUserActivity *activity = [self wmf_activityWithType:@"topread"];
    activity.eligibleForSearch = NO;
    activity.eligibleForHandoff = NO;
    activity.eligibleForPublicIndexing = NO;
    if (siteURL && date) {
        activity.userInfo = @{ @"siteURL": siteURL,
                               @"date": date };
    }
    return activity;
}

+ (instancetype)wmf_searchResultsActivitySearchSiteURL:(NSURL *)url searchTerm:(NSString *)searchTerm {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.path = @"/w/index.php";
    components.query = [NSString stringWithFormat:@"search=%@&title=Special:Search&fulltext=1", searchTerm];
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
        } else if ([page isEqualToString:@"Saved"]) {
            return WMFUserActivityTypeSavedPages;
        } else if ([page isEqualToString:@"History"]) {
            return WMFUserActivityTypeHistory;
        } else if ([page isEqualToString:@"Search"]) {
            return WMFUserActivityTypeSearch;
        } else {
            return WMFUserActivityTypeSettings;
        }
    } else if ([self.activityType hasSuffix:@".topread"]) {
        return WMFUserActivityTypeTopRead;
    } else if ([self.webpageURL.absoluteString containsString:@"/w/index.php?search="]) {
        return WMFUserActivityTypeSearchResults;
    } else if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:10] && [self.activityType isEqualToString:CSQueryContinuationActionType]) {
        return WMFUserActivityTypeSearchResults;
    } else {
        return WMFUserActivityTypeArticle;
    }
}

- (NSString *)wmf_searchTerm {
    if (self.wmf_type != WMFUserActivityTypeSearchResults) {
        return nil;
    }

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:10] && [self.activityType isEqualToString:CSQueryContinuationActionType]) {
        return self.userInfo[CSSearchQueryString];
    } else {
        NSURLComponents *components = [NSURLComponents componentsWithString:self.webpageURL.absoluteString];
        NSArray *queryItems = components.queryItems;
        NSURLQueryItem *item = [queryItems bk_match:^BOOL(NSURLQueryItem *obj) {
            if ([[obj name] isEqualToString:@"search"]) {
                return YES;
            } else {
                return NO;
            }
        }];
        return [item value];
    }
}

- (NSURL *)wmf_articleURL {
    if (self.userInfo[CSSearchableItemActivityIdentifier] != nil) {
        return [NSURL URLWithString:self.userInfo[CSSearchableItemActivityIdentifier]];
    } else {
        return self.webpageURL;
    }
}

@end
