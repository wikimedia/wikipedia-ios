//
//  MWKArticleLeadSectionHTMLVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/28/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "WMFTestFixtureUtilities.h"
#import "MWKArticle.h"
#import "WMFMinimalArticleContentController.h"
#import "XCTestCase+PromiseKit.h"

#import <DTCoreText/DTAttributedTextContentView.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface WMFArticleSummaryVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) MWKArticle* article;
@end

@implementation WMFArticleSummaryVisualTests

- (void)setUp {
    [super setUp];
//    self.recordMode = YES;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testExoplanetPortraitIPhone6Width {
    [self verifySummaryForFixture:@"Exoplanet.mobileview"];
}

- (void)testObamaPortraitIPhone6Width {
    [self verifySummaryForFixture:@"Obama"];
}

- (void)verifySummaryForFixture:(NSString*)fixtureFilename {
    NSDictionary* mobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureFilename];

    MWKTitle* title =
        [MWKTitle titleWithString:@"Title" site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];

    self.article = [[MWKArticle alloc] initWithTitle:title
                                           dataStore:nil
                                                dict:mobileViewJSON[@"mobileview"]];

    WMFMinimalArticleContentController* minimalContentController = [[WMFMinimalArticleContentController alloc] init];

    DTAttributedTextContentView* testView = [[DTAttributedTextContentView alloc] init];
    [minimalContentController configureContentView:testView];
    testView.attributedString = self.article.summaryHTML;
    testView.frame            = (CGRect){
        .origin = CGPointZero,
        .size   = [testView suggestedFrameSizeToFitEntireStringConstraintedToWidth:320]
    };

    // pass nil to get description based on current test
    FBSnapshotVerifyView(testView, nil);
}

@end
