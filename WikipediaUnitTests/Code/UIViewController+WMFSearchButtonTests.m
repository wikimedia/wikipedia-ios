//
//  UIViewController+WMFSearchButtonTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "UIViewController+WMFSearch.h"
#import "WMFSearchViewController.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "SessionSingleton.h"

@interface UIViewController (WMFSharedTestAccess)

+ (WMFSearchViewController*)sharedSearchViewController;
+ (void)                    wmf_clearSearchViewController;

@end

QuickSpecBegin(UIViewController_WMFSearchButtonTests)

static UIWindow * window = nil;
static UIViewController* testVC = nil;

beforeSuite(^{
    [UIViewController wmf_setSearchButtonDataStore:[MWKDataStore temporaryDataStore]];
    testVC = [UIViewController new];
    window = [[UIWindow alloc] init];
    window.rootViewController = testVC;
    [window makeKeyAndVisible];
});

afterEach(^{
    // tear down search
    if ([UIViewController sharedSearchViewController].view.window) {
        [[UIViewController sharedSearchViewController] dismissViewControllerAnimated:NO completion:nil];

        [self expectationForPredicate:
         [NSPredicate predicateWithBlock:
          ^BOOL (UIViewController* _Nonnull evaluatedObject, NSDictionary < NSString*, id > * _Nullable bindings) {
            return evaluatedObject.view.window == nil;
        }]        evaluatedWithObject:[UIViewController sharedSearchViewController] handler:nil];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }

    [UIViewController wmf_clearSearchViewController];
    [testVC.view.window resignKeyWindow];
});


describe(@"search button", ^{
    it(@"should have the same (correct) site when presented consecutively", ^{
        [testVC wmf_showSearchAnimated:NO];

        WMFSearchViewController* oldSearchVC = [UIViewController sharedSearchViewController];
        [oldSearchVC dismissViewControllerAnimated:NO completion:NULL];

        [testVC wmf_showSearchAnimated:NO];

        expect([UIViewController sharedSearchViewController]).to(equal(oldSearchVC));

        expect([UIViewController sharedSearchViewController].searchSite).to(equal(oldSearchVC.searchSite));
    });

    it(@"should have correct site when presented after changes to search site", ^{
        [testVC wmf_showSearchAnimated:NO];

        WMFSearchViewController* oldSearchVC = [UIViewController sharedSearchViewController];
        [oldSearchVC dismissViewControllerAnimated:NO completion:NULL];

        [[SessionSingleton sharedInstance] setSearchLanguage:
         [[[SessionSingleton sharedInstance] searchLanguage] stringByAppendingString:@"a"]];

        [testVC wmf_showSearchAnimated:NO];

        expect([UIViewController sharedSearchViewController]).toNot(equal(oldSearchVC));
    });

    it(@"should be presentable from different view controllers", ^{
        [testVC wmf_showSearchAnimated:NO];

        WMFSearchViewController* oldSearchVC = [UIViewController sharedSearchViewController];
        [oldSearchVC dismissViewControllerAnimated:NO completion:NULL];

        UIViewController* otherTestVC = [UIViewController new];
        testVC.view.window.rootViewController = otherTestVC;
        [otherTestVC wmf_showSearchAnimated:NO];
        expect([UIViewController sharedSearchViewController]).to(equal(oldSearchVC));
    });
});

describe(@"global searchVC", ^{
    void (^ verifyGlobalVCOutOfWindowResetAfterNotificationNamed)(NSString*) = ^(NSString* notificationName) {
        [testVC wmf_showSearchAnimated:NO];

        expect([UIViewController sharedSearchViewController]).toNot(beNil());

        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];

        expect([UIViewController sharedSearchViewController]).to(beNil());
    };

    it(@"should be reset on memory warnings when it is not in the window", ^{
        verifyGlobalVCOutOfWindowResetAfterNotificationNamed(UIApplicationDidReceiveMemoryWarningNotification);
    });

    it(@"should reset when the app enters the background if it's not in the window", ^{
        verifyGlobalVCOutOfWindowResetAfterNotificationNamed(UIApplicationDidEnterBackgroundNotification);
    });
});

QuickSpecEnd
