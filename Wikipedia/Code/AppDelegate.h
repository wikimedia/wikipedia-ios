
#import <UIKit/UIKit.h>

static NSString* const WMFIconShortcutTypeSearch          = @"org.wikimedia.wikipedia.icon-shortcut-search";
static NSString* const WMFIconShortcutTypeContinueReading = @"org.wikimedia.wikipedia.icon-shortcut-continue-reading";
static NSString* const WMFIconShortcutTypeRandom          = @"org.wikimedia.wikipedia.icon-shortcut-random";
static NSString* const WMFIconShortcutTypeNearby          = @"org.wikimedia.wikipedia.icon-shortcut-nearby";

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow* window;

// HAX
@property (nonatomic, strong) UIApplicationShortcutItem* shortcutItemSelectedAtLaunch;

@end
