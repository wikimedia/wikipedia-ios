#import "UIApplicationShortcutItem+WMFShortcutItem.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFIconShortcutTypeSearch = @"org.wikimedia.wikipedia.icon-shortcut-search";
NSString *const WMFIconShortcutTypeContinueReading = @"org.wikimedia.wikipedia.icon-shortcut-continue-reading";
NSString *const WMFIconShortcutTypeRandom = @"org.wikimedia.wikipedia.icon-shortcut-random";
NSString *const WMFIconShortcutTypeNearby = @"org.wikimedia.wikipedia.icon-shortcut-nearby";

@implementation UIApplicationShortcutItem (WMFShortcutItem)

+ (UIApplicationShortcutItem *)wmf_search {
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeSearch
                                            localizedTitle:WMFLocalizedStringWithDefaultValue(@"icon-shortcut-search-title", nil, nil, @"Search Wikipedia", @"Title for app icon force touch shortcut to quickly open the search interface.")
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"search"]
                                                  userInfo:nil];
}

+ (UIApplicationShortcutItem *)wmf_random {
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeRandom
                                            localizedTitle:WMFLocalizedStringWithDefaultValue(@"icon-shortcut-random-title", nil, nil, @"Random article", @"Title for app icon force touch shortcut to quickly open a random article.\n{{Identical|Random article}}")
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"random-quick-action"]
                                                  userInfo:nil];
}

+ (nullable UIApplicationShortcutItem *)wmf_continueReading {
    NSURL *lastRead = [[NSUserDefaults wmf_userDefaults] wmf_openArticleURL];
    if (lastRead.wmf_title.length == 0) {
        return nil;
    }
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeContinueReading
                                            localizedTitle:WMFLocalizedStringWithDefaultValue(@"icon-shortcut-continue-reading-title", nil, nil, @"Continue reading", @"Title for app icon force touch shortcut to quickly re-open the last article the user was reading.")
                                         localizedSubtitle:lastRead.wmf_title
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"home-continue-reading-mini"]
                                                  userInfo:nil];
}

+ (UIApplicationShortcutItem *)wmf_nearby {
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeNearby
                                            localizedTitle:WMFLocalizedStringWithDefaultValue(@"icon-shortcut-nearby-title", nil, nil, @"Nearby articles", @"Title for app icon force touch shortcut to quickly open the nearby articles interface.")
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"nearby-quick-action"]
                                                  userInfo:nil];
}

@end

NS_ASSUME_NONNULL_END
