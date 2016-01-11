//  Created by Monte Hurd on 1/11/16.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

extern NSString* const WMFIconShortcutTypeSearch;
extern NSString* const WMFIconShortcutTypeContinueReading;
extern NSString* const WMFIconShortcutTypeRandom;
extern NSString* const WMFIconShortcutTypeNearby;

@interface UIApplicationShortcutItem (WMFShortcutItem)

+ (UIApplicationShortcutItem*)wmf_shortcutItemOfType:(NSString*)type;

@end
