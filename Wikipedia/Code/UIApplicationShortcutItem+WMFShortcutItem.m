//  Created by Monte Hurd on 1/11/16.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIApplicationShortcutItem+WMFShortcutItem.h"
#import "Wikipedia-Swift.h"

NSString* const WMFIconShortcutTypeSearch          = @"org.wikimedia.wikipedia.icon-shortcut-search";
NSString* const WMFIconShortcutTypeContinueReading = @"org.wikimedia.wikipedia.icon-shortcut-continue-reading";
NSString* const WMFIconShortcutTypeRandom          = @"org.wikimedia.wikipedia.icon-shortcut-random";
NSString* const WMFIconShortcutTypeNearby          = @"org.wikimedia.wikipedia.icon-shortcut-nearby";

@implementation UIApplicationShortcutItem (WMFShortcutItem)

+ (UIApplicationShortcutItem*)wmf_shortcutItemOfType:(NSString*)type {
    NSString* title    = @"";
    NSString* icon     = @"";
    NSString* subtitle = @"";

    if ([type isEqualToString:WMFIconShortcutTypeSearch]) {
        title = @"icon-shortcut-search-title";
        icon  = @"search";
    } else if ([type isEqualToString:WMFIconShortcutTypeContinueReading]) {
        title = @"icon-shortcut-continue-reading-title";
        icon  = @"home-continue-reading-mini";
        MWKTitle* lastRead = [[NSUserDefaults standardUserDefaults] wmf_openArticleTitle];
        if (lastRead) {
            subtitle = lastRead.text;
        }
    } else if ([type isEqualToString:WMFIconShortcutTypeRandom]) {
        title = @"icon-shortcut-random-title";
        icon  = @"random-quick-action";
    } else if ([type isEqualToString:WMFIconShortcutTypeNearby]) {
        title = @"icon-shortcut-nearby-title";
        icon  = @"nearby-quick-action";
    }

    NSAssert(title.length > 0, @"Unknown icon shortcut type.");

    return [[UIApplicationShortcutItem alloc] initWithType:type
                                            localizedTitle:MWLocalizedString(title, nil)
                                         localizedSubtitle:subtitle
                                                      icon:[UIApplicationShortcutIcon iconWithTemplateImageName:icon]
                                                  userInfo:nil];
}

@end
