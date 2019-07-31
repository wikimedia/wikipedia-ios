#import "UIApplicationShortcutItem+WMFShortcutItem.h"
@import WMF.Swift;
@import WMF.WMFLocalization;
@import WMF.NSURL_WMFLinkParsing;

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
                                            localizedTitle:WMFLocalizedStringWithDefaultValue(@"icon-shortcut-random-title", nil, nil, @"Random article", @"Title for app icon force touch shortcut to quickly open a random article. {{Identical|Random article}}")
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"random-quick-action"]
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
