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
    [self verifySummaryForFixture:@"Exoplanet.mobileview" languageCode:@"en"];
}

- (void)testObamaPortraitIPhone6Width {
    [self verifySummaryForFixture:@"Obama" languageCode:@"en"];
}

- (void)testTajMahalPortraitIPhone6Width {
    NSData* mobileViewData =
        [[self wmf_bundle] wmf_dataFromContentsOfFile:@"MobileView/ar.m.wikipedia.org/تاج محل"
                                               ofType:@""];
    [self verifySummaryForFixtureData:
     [NSJSONSerialization JSONObjectWithData:mobileViewData options:0 error:nil]
                             langCode:@"ar"];
}

- (void)verifySummaryForFixture:(NSString*)fixtureFilename languageCode:(NSString*)langCode {
    NSDictionary* mobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:fixtureFilename];
    [self verifySummaryForFixtureData:mobileViewJSON langCode:langCode];
}

- (void)verifySummaryForFixtureData:(NSDictionary*)mobileViewJSON langCode:(NSString*)langCode  {
    MWKTitle* title =
        [MWKTitle titleWithString:@"Title" site:[MWKSite siteWithDomain:@"wikipedia.org"
                                                               language:langCode]];

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
