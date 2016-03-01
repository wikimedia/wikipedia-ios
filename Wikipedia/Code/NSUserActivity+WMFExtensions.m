
#import "NSUserActivity+WMFExtensions.h"
#import "MWKArticle.h"
#import "MWKTitle.h"
#import "MWKSite.h"
#import "Wikipedia-Swift.h"

@import CoreSpotlight;
@import MobileCoreServices;

@implementation NSUserActivity (WMFExtensions)

+ (void)wmf_makeActivityActive:(NSUserActivity*)activity {
    static NSUserActivity* _current = nil;

    if (_current) {
        [_current invalidate];
        _current = nil;
    }

    _current = activity;
    [_current becomeCurrent];
}

+ (instancetype)wmf_actvityWithType:(NSString*)type {
    NSUserActivity* activity = [[NSUserActivity alloc] initWithActivityType:[NSString stringWithFormat:@"org.wikimedia.wikipedia.%@", [type lowercaseString]]];

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        activity.eligibleForHandoff        = YES;
        activity.eligibleForSearch         = YES;
        activity.eligibleForPublicIndexing = YES;
        activity.keywords                  = [NSSet setWithArray:@[@"Wikipedia", @"Wikimedia", @"Wiki"]];
    }
    return activity;
}

+ (instancetype)wmf_pageActivityWithName:(NSString*)pageName {
    NSUserActivity* activity = [self wmf_actvityWithType:[pageName lowercaseString]];
    activity.title    = pageName;
    activity.userInfo = @{@"WMFPage": pageName};

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        NSMutableSet* set = [activity.keywords mutableCopy];
        [set addObjectsFromArray:[pageName componentsSeparatedByString:@" "]];
        activity.keywords = set;
    }

    return activity;
}

+ (instancetype)wmf_exploreViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Explore"];
    return activity;
}

+ (instancetype)wmf_savedPagesViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Saved"];
    return activity;
}

+ (instancetype)wmf_recentViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"History"];
    return activity;
}

+ (instancetype)wmf_searchViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Search"];
    return activity;
}

+ (instancetype)wmf_settingsViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Settings"];
    return activity;
}

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle*)article {
    NSParameterAssert(article.title.mobileURL);
    NSParameterAssert(article.title.text);
    NSParameterAssert(article.displaytitle);

    NSUserActivity* activity = [self wmf_actvityWithType:@"article"];
    activity.title      = article.displaytitle;
    activity.webpageURL = article.title.desktopURL;

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        NSMutableSet* set = [activity.keywords mutableCopy];
        [set addObjectsFromArray:[article.title.text componentsSeparatedByString:@" "]];
        activity.keywords       = set;
        activity.expirationDate = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * 30];

        CSSearchableItemAttributeSet* attributes = [CSSearchableItemAttributeSet attributes:article];
        attributes.relatedUniqueIdentifier = [article.title.desktopURL absoluteString];
        activity.contentAttributeSet       = attributes;
    }

    return activity;
}

+ (instancetype)wmf_searchResultsActivitySearchSite:(MWKSite*)site searchTerm:(NSString*)searchTerm {
    NSURL* url                  = [site URL];
    NSURLComponents* components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.path = [NSString stringWithFormat:@"/w/index.php?search=%@&title=Special%%3ASearch&fulltext=1", searchTerm];
    url             = [components URL];

    NSUserActivity* activity = [self wmf_actvityWithType:@"Searchresults"];

    activity.title      = [NSString stringWithFormat:@"Search for %@", searchTerm];
    activity.webpageURL = url;

    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemMajorVersionAtLeast:9]) {
        activity.eligibleForSearch         = NO;
        activity.eligibleForPublicIndexing = NO;
    }

    return activity;
}

- (WMFUserActivityType)wmf_type {
    if (self.userInfo[@"WMFPage"] != nil) {
        NSString* page = self.userInfo[@"WMFPage"];
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
    } else if ([self.webpageURL.absoluteString containsString:@"/w/index.php?search="]) {
        return WMFUserActivityTypeSearchResults;
    } else {
        return WMFUserActivityTypeArticle;
    }
}

- (NSString*)wmf_searchTerm {
    if (self.wmf_type != WMFUserActivityTypeSearchResults) {
        return nil;
    }

    NSURLComponents* components = [NSURLComponents componentsWithString:self.webpageURL.absoluteString];
    NSArray* queryItems         = components.queryItems;
    NSURLQueryItem* item        = [queryItems bk_match:^BOOL (NSURLQueryItem* obj) {
        if ([[obj name] isEqualToString:@"search"]) {
            return YES;
        } else {
            return NO;
        }
    }];

    return [item value];
}

@end

