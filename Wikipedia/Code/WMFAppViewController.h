#import <UIKit/UIKit.h>

@interface WMFAppViewController : UIViewController

+ (instancetype)initialAppViewControllerFromDefaultStoryBoard;

- (void)launchAppInWindow:(UIWindow*)window;

- (void)processShortcutItem:(UIApplicationShortcutItem*)item completion:(void (^)(BOOL))completion;

- (BOOL)processUserActivity:(NSUserActivity*)activity;

@end
