//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

#if DEBUG
/**
 *  Dummy application delegate for use in unit testing.
 *
 *  Visual tests require that the application has a @c keyWindow, and we don't pass the regular application delegate to
 *  prevent unintended side effects from regular application code when testing.
 */
@interface WMFDummyAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow* window;
@end

@implementation WMFDummyAppDelegate

- (UIWindow*)window {
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _window;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(nullable NSDictionary*)launchOptions {
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
#endif

int main(int argc, char* argv[]) {
    @autoreleasepool {
        NSString* delegateClass = NSStringFromClass([AppDelegate class]);
#if DEBUG
        // disable app when unit testing to allow tests to run in isolation (w/o side effects)
        if (NSClassFromString(@"XCTestCase") != nil) {
            delegateClass = NSStringFromClass([WMFDummyAppDelegate class]);
        }
#endif
        return UIApplicationMain(argc, argv, nil, delegateClass);
    }
}

