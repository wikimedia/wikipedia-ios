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

@interface WMFShareSnippetTests : XCTestCase
@property MWKArticle* article;
@end

@implementation WMFShareSnippetTests

- (void)setUp {
    [super setUp];
    NSDictionary* obamaMobileViewJSON = [[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"];
    MWKTitle* dummyTitle =
        [MWKTitle titleWithString:@"foo" site:[MWKSite siteWithDomain:@"wikipedia.org" language:@"en"]];
    self.article = [[MWKArticle alloc] initWithTitle:dummyTitle dataStore:nil dict:obamaMobileViewJSON[@"mobileview"]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExpectedSnippetForObamaArticle {
    assertThat(self.article.shareSnippet, is(@"Obama was born on August 4, 1961, at Kapiʻolani Maternity & Gynecological Hospital in Honolulu, Hawaii, and would become the first President to have been born in Hawaii. His mother, Stanley Ann Dunham, was born in Wichita, Kansas, and was of mostly English ancestry. His fa"));
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        [self.article shareSnippet];
    }];
}

@end
