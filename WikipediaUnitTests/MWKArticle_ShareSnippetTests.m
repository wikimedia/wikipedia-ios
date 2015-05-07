//
//  WMFShareSnippetTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFTestFixtureUtilities.h"
#import "MWKTitle.h"
#import "MWKSite.h"
#import "MWKArticle+ShareSnippet.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKArticle_ShareSnippetTests : XCTestCase
@property MWKArticle* article;
@end

@implementation MWKArticle_ShareSnippetTests

- (void)setUp {
    [super setUp];
    NSDictionary* obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
    MWKTitle* dummyTitle              =
        [MWKTitle titleWithString:@"foo" site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];
    self.article = [[MWKArticle alloc] initWithTitle:dummyTitle dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExpectedSnippetForObamaArticle {
    assertThat(self.article.shareSnippet, is(@"Barack Hussein Obama II is the 44th and current President of the United States, and the first African American to hold the office. Born in Honolulu, Hawaii, Obama is a graduate of Columbia University and Harvard Law School, where he served as president of the Harvard Law Review. He was a community organizer in Chicago before earning his law degree. He worked as a civil rights attorney and taught constitutional law at the University of Chicago Law School from 1992 to 2004. He served three terms representing the 13th District in the Illinois Senate from 1997 to 2004, running unsuccessfully for the United States House of Representatives in 2000."));
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        [self.article shareSnippet];
    }];
}

@end
