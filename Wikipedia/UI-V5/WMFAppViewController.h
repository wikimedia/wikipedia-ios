
#import <UIKit/UIKit.h>

@interface WMFAppViewController : UIViewController

+ (instancetype)initialAppViewControllerFromDefaultStoryBoard;

- (void)launchAppInWindow:(UIWindow*)window;

- (void)resumeApp;

@end
