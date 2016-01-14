//
//  UIViewController+WMFSearchButtonTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 12/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "UIViewController+WMFSearchButton_Testing.h"
#import "WMFSearchViewController.h"
#import "MWKDataStore+TempDataStoreForEach.h"
#import "SessionSingleton.h"

@interface DummySearchPresentationViewController : UIViewController
    <WMFSearchPresentationDelegate>

@property (nonatomic, strong) MWKDataStore* searchDataStore;

@end

QuickSpecBegin(UIViewController_WMFSearchButtonTests)

__block DummySearchPresentationViewController* testVC;
configureTempDataStoreForEach(tempDataStore, ^{
    testVC = [DummySearchPresentationViewController new];
    testVC.searchDataStore = tempDataStore;
    UIWindow* tempWindow = [[UIWindow alloc] init];
    tempWindow.rootViewController = testVC;
    [tempWindow makeKeyAndVisible];
});

afterEach(^{
    // tear down search
    if (_sharedSearchViewController.view.window) {
        [_sharedSearchViewController dismissViewControllerAnimated:NO completion:nil];

        [self expectationForPredicate:
         [NSPredicate predicateWithBlock:
          ^BOOL (UIViewController* _Nonnull evaluatedObject, NSDictionary < NSString*, id > * _Nullable bindings) {
            return evaluatedObject.view.window == nil;
        }]        evaluatedWithObject:_sharedSearchViewController handler:nil];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }

    _sharedSearchViewController = nil;
    [testVC.view.window resignKeyWindow];
});

WMFSearchViewController*(^ presentSearchByTappingButtonInVC)(UIViewController<WMFSearchPresentationDelegate>*) =
    ^(UIViewController<WMFSearchPresentationDelegate>* presentingVC) {
    UIBarButtonItem* searchBarItem = [presentingVC wmf_searchBarButtonItemWithDelegate:presentingVC];

    // perform search button press manually
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [searchBarItem.target performSelector:searchBarItem.action withObject:searchBarItem];
    #pragma clang diagnostic pop

    // using XCTestExpecation because Nimble's polling matchers are failing on Travis
    [self expectationForPredicate:
     [NSPredicate predicateWithBlock:
      ^BOOL (UIViewController* _Nonnull evaluatedObject, NSDictionary < NSString*, id > * _Nullable bindings) {
        return evaluatedObject.presentedViewController.view.window != nil;
    }]        evaluatedWithObject:presentingVC handler:nil];
    [self waitForExpectationsWithTimeout:10 handler:nil];

    WMFSearchViewController* searchVC = (WMFSearchViewController*)presentingVC.presentedViewController;

    expect(searchVC).to(beAnInstanceOf([WMFSearchViewController class]));
    expect(searchVC).to(equal(_sharedSearchViewController));
    expect(searchVC.searchResultDelegate).to(equal(presentingVC));
    expect(searchVC.searchSite).to(equal([[SessionSingleton sharedInstance] searchSite]));

    return searchVC;
};

void (^ dismissSearchFromVCAndWait)(UIViewController*) = ^(UIViewController* vc) {
    UIViewController* presentedVC = vc.presentedViewController;
    [vc dismissViewControllerAnimated:NO completion:nil];
    [self expectationForPredicate:
     [NSPredicate predicateWithBlock:
      ^BOOL (UIViewController* _Nonnull evaluatedObject, NSDictionary < NSString*, id > * _Nullable bindings) {
        return presentedVC.view.window == nil;
    }]        evaluatedWithObject:presentedVC handler:nil];
    [self waitForExpectationsWithTimeout:10 handler:nil];
};

void (^ dismissSearchFromTestVCAndWait)() = ^() {
    dismissSearchFromVCAndWait(testVC);
};

describe(@"search button", ^{
    it(@"should present a search VC modally", ^{
        presentSearchByTappingButtonInVC(testVC);
    });

    it(@"should have the same (correct) delegate & site when presented consecutively", ^{
        WMFSearchViewController* firstSearchVC = presentSearchByTappingButtonInVC(testVC);

        dismissSearchFromTestVCAndWait();

        WMFSearchViewController* secondSearchVC = presentSearchByTappingButtonInVC(testVC);
        expect(secondSearchVC).to(equal(firstSearchVC));
        expect(secondSearchVC.searchSite).to(equal(firstSearchVC.searchSite));
    });

    it(@"should have correct delegate & site when presented after changes to search site", ^{
        WMFSearchViewController* oldSearchVC = presentSearchByTappingButtonInVC(testVC);

        dismissSearchFromTestVCAndWait();

        [[SessionSingleton sharedInstance] setSearchLanguage:
         [[[SessionSingleton sharedInstance] searchLanguage] stringByAppendingString:@"a"]];

        expect(presentSearchByTappingButtonInVC(testVC)).toNot(equal(oldSearchVC));
    });

    it(@"should be presentable from different view controllers", ^{
        WMFSearchViewController* oldSearchVC = presentSearchByTappingButtonInVC(testVC);
        dismissSearchFromTestVCAndWait();

        DummySearchPresentationViewController* otherTestVC = [DummySearchPresentationViewController new];
        otherTestVC.searchDataStore = testVC.searchDataStore;
        testVC.view.window.rootViewController = otherTestVC;
        WMFSearchViewController* newSearchVC = presentSearchByTappingButtonInVC(otherTestVC);
        expect(newSearchVC).to(equal(oldSearchVC));
    });
});

describe(@"global searchVC", ^{
    void (^ verifyGlobalVCOutOfWindowResetAfterNotificationNamed)(NSString*) = ^(NSString* notificationName) {
        presentSearchByTappingButtonInVC(testVC);

        expect(_sharedSearchViewController).toNot(beNil());

        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];

        expect(_sharedSearchViewController).toNot(beNil());

        dismissSearchFromTestVCAndWait();

        expect(_sharedSearchViewController).toNot(beNil());

        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];

        expect(_sharedSearchViewController).to(beNil());
    };

    it(@"should be reset on memory warnings when it is not in the window", ^{
        verifyGlobalVCOutOfWindowResetAfterNotificationNamed(UIApplicationDidReceiveMemoryWarningNotification);
    });

    it(@"should reset when the app enters the background if it's not in the window", ^{
        verifyGlobalVCOutOfWindowResetAfterNotificationNamed(UIApplicationDidEnterBackgroundNotification);
    });
});

QuickSpecEnd

@implementation DummySearchPresentationViewController

#pragma mark - WMFSearchPresentationDelegate

- (void)didCommitToPreviewedArticleViewController:(WMFArticleContainerViewController*)articleViewController
                                           sender:(id)sender {
    WMF_TECH_DEBT_TODO(verify these callbacks)
}

- (void)didSelectTitle:(MWKTitle*)title sender:(id)sender discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    WMF_TECH_DEBT_TODO(verify these callbacks)
}

@end
