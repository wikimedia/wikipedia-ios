#import <UIKit/UIKit.h>

#import "AppDelegate.h"

#if TEST

/**
 *  Dummy application delegate for use in unit testing. This is used for 2 reasons:
 *
 *  1. Visual tests require that the application has a @c keyWindow, and we don't pass the regular application delegate to
 *  prevent unintended side effects from regular application code when testing.
 *
 *  2. Stubbed networking tests can fail if unexpected network operations are triggered by the application.
 */
@interface WMFDummyAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation WMFDummyAppDelegate

- (UIWindow *)window {
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
#endif

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *delegateClass = NSStringFromClass([AppDelegate class]);
#if TEST
        // disable app when unit testing to allow tests to run in isolation (w/o side effects)
        if (NSClassFromString(@"XCTestCase") != nil) {
            delegateClass = NSStringFromClass([WMFDummyAppDelegate class]);
        }
#endif
        return UIApplicationMain(argc, argv, nil, delegateClass);
    }
}
