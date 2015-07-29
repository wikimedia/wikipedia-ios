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
#import "WMFArticleViewController.h"

@interface MWKArticleLeadSectionHTMLVisualTests : FBSnapshotTestCase
@property (nonatomic) MWKArticle* article;
@end

@implementation MWKArticleLeadSectionHTMLVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = YES;
}

- (void)testObamaArticle {
    NSDictionary* obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
    MWKTitle* dummyTitle              =
        [MWKTitle titleWithString:@"foo" site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];
    self.article = [[MWKArticle alloc] initWithTitle:dummyTitle dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
}

@end
