
#import <UIKit/UIKit.h>

@interface UIStoryboard (WMFDefaultStoryBoard)

+ (UIStoryboard*)wmf_defaultStoryBoard;

@end

@interface WMFAppViewController : UIViewController

+ (instancetype)initialAppViewControllerFromDefaultStoryBoard;

- (void)launchAppInWindow:(UIWindow*)window;

- (void)resumeApp;

@end
