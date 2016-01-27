//
//  WMFWelcomeLanguageViewControllerVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/26/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

@import Nimble;
#import "FBSnapshotTestCase+WMFConvenience.h"
#import "UIView+VisualTestSizingUtils.h"

#import "WMFWelcomeLanguageViewController_Testing.h"
#import "MWKLanguageLinkController_Private.h"
#import "UIViewController+WMFStoryboardUtilities.h"

@interface WMFWelcomeLanguageViewControllerVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) WMFWelcomeLanguageViewController* welcomeLanguageVC;

@end

@implementation WMFWelcomeLanguageViewControllerVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode     = NO;
    self.deviceAgnostic = YES;

    // NOTE(bgerstle): test might be terminated before tearDown when debugging, so we should clean up before re-running
    [[MWKLanguageLinkController sharedInstance] resetPreferredLanguages];

    self.welcomeLanguageVC = [WMFWelcomeLanguageViewController wmf_viewControllerWithIdentifier:@"language-selection"
                                                                            fromStoryboardNamed:@"WMFWelcome"];
    self.welcomeLanguageVC.view.frame = [[[UIApplication sharedApplication] keyWindow] bounds];
}

- (void)tearDown {
    [[MWKLanguageLinkController sharedInstance] resetPreferredLanguages];
    [super tearDown];
}

- (void)testShowsCurrentLanguageList {
    if ([[MWKLanguageLinkController sharedInstance] preferredLanguages].count < 1) {
        [[MWKLanguageLinkController sharedInstance] addPreferredLanguageForCode:@"en"];
        [self.welcomeLanguageVC languagesController:nil didSelectLanguage:[[MWKLanguageLinkController sharedInstance] preferredLanguages].firstObject];
    }

    WMFSnapshotVerifyViewForOSAndWritingDirection(self.welcomeLanguageVC.view);

    // NOTE(bgerstle): expectation must be checked after snapshot is taken, and layout has occurred
    // this asserts that the view is in the proper logical state given it is in the proper visual state.
    expect(@(self.welcomeLanguageVC.languageTableView.isScrollEnabled))
    .toWithDescription(
        beFalse(),
        @"Language selection table should prevent scrolling/bouncing when content fits the screen (after layout).");
}

- (void)testLetsLanguagesOverflowOffscreen {
    [[[[MWKLanguageLinkController sharedInstance]
       otherLanguages]
      subarrayWithRange:NSMakeRange(0, 10)]
     bk_each:^(MWKLanguageLink* link) {
        [self.welcomeLanguageVC languagesController:nil didSelectLanguage:link];
    }];

    WMFSnapshotVerifyViewForOSAndWritingDirection(self.welcomeLanguageVC.view);

    expect(@(self.welcomeLanguageVC.languageTableView.isScrollEnabled))
    .toWithDescription(
        beTrue(),
        @"Language selection table should allow scrolling/bouncing when content flows offscreen (after layout).");
}

@end
