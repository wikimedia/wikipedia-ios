//  Created by Monte Hurd on 1/11/16.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIApplicationShortcutItem+WMFShortcutItem.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const WMFIconShortcutTypeSearch          = @"org.wikimedia.wikipedia.icon-shortcut-search";
NSString* const WMFIconShortcutTypeContinueReading = @"org.wikimedia.wikipedia.icon-shortcut-continue-reading";
NSString* const WMFIconShortcutTypeRandom          = @"org.wikimedia.wikipedia.icon-shortcut-random";
NSString* const WMFIconShortcutTypeNearby          = @"org.wikimedia.wikipedia.icon-shortcut-nearby";

@implementation UIApplicationShortcutItem (WMFShortcutItem)

+ (UIApplicationShortcutItem*)wmf_search {
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeSearch
                                            localizedTitle:MWLocalizedString(@"icon-shortcut-search-title", nil)
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"search"]
                                                  userInfo:nil];
}

+ (UIApplicationShortcutItem*)wmf_random {
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeRandom
                                            localizedTitle:MWLocalizedString(@"icon-shortcut-random-title", nil)
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"random-quick-action"]
                                                  userInfo:nil];
}

+ (nullable UIApplicationShortcutItem*)wmf_continueReading {
    MWKTitle* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleTitle];
    if (lastRead.text.length == 0) {
        return nil;
    }
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeContinueReading
                                            localizedTitle:MWLocalizedString(@"icon-shortcut-continue-reading-title", nil)
                                         localizedSubtitle:lastRead.text
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"home-continue-reading-mini"]
                                                  userInfo:nil];
}

+ (UIApplicationShortcutItem*)wmf_nearby {
    return [[UIApplicationShortcutItem alloc] initWithType:WMFIconShortcutTypeNearby
                                            localizedTitle:MWLocalizedString(@"icon-shortcut-nearby-title", nil)
                                         localizedSubtitle:@""
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"nearby-quick-action"]
                                                  userInfo:nil];
}

@end

NS_ASSUME_NONNULL_END
