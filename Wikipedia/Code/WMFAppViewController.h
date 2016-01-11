
#import <UIKit/UIKit.h>

@interface WMFAppViewController : UIViewController

+ (instancetype)initialAppViewControllerFromDefaultStoryBoard;

- (void)launchAppInWindow:(UIWindow*)window;

@property (nonatomic, strong) UIApplicationShortcutItem* shortcutItemSelectedAtLaunch;

@end
