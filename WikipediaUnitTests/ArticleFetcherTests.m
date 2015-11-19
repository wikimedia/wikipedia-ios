//
//  ArticleFetcherTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WMFArticleFetcher.h"
#import "MWKDataStore+TemporaryDataStore.h"
#import "MWKArticle.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "WMFTestFixtureUtilities.h"
#import "SessionSingleton.h"
#import <Nocilla/Nocilla.h>
#import "Wikipedia-Swift.h"

#import "XCTestCase+PromiseKit.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface ArticleFetcherTests : XCTestCase

@property (strong, nonatomic) MWKDataStore* tempDataStore;
@property (strong, nonatomic) WMFArticleFetcher* articleFetcher;

@end

@implementation ArticleFetcherTests

- (void)setUp {
    [super setUp];
    self.tempDataStore  = [MWKDataStore temporaryDataStore];
    self.articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.tempDataStore];
    [[LSNocilla sharedInstance] start];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [self.tempDataStore removeFolderAtBasePath];
    self.tempDataStore  = nil;
    self.articleFetcher = nil;
    [super tearDown];
}

- (void)testSuccessfulFetchWritesArticleToDataStoreWithoutDuplicatingData {
    MWKSite* site        = [MWKSite siteWithDomain:@"wikipedia.org" language:@"en"];
    MWKTitle* dummyTitle = [site titleWithString:@"Foo"];
    NSURL* url           = [site mobileApiEndpoint];

    NSString* json = [[self wmf_bundle] wmf_stringFromContentsOfFile:@"Obama" ofType:@"json"];

    // TODO: refactor into convenience method
    NSRegularExpression* anyRequestFromTestSite =
        [NSRegularExpression regularExpressionWithPattern:
         [NSString stringWithFormat:@"%@.*", [url absoluteString]] options:0 error:nil];

    stubRequest(@"GET", anyRequestFromTestSite)
    .andReturn(200)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(json);

    __block MWKArticle* firstArticle;

    expectResolutionWithTimeout(5, ^{
        return [self.articleFetcher fetchArticleForPageTitle:dummyTitle progress:NULL].then(^(MWKArticle* article){
            assertThat(article.displaytitle, is(equalTo(@"Barack Obama")));

            MWKArticle* savedArticle = [self.tempDataStore articleWithTitle:dummyTitle];
            assertThat(article, is(equalTo(savedArticle)));
            assertThat(@([article isDeeplyEqualToArticle:savedArticle]), isTrue());

            firstArticle = article;

            return [self.articleFetcher fetchArticleForPageTitle:dummyTitle progress:NULL];
        }).then(^(MWKArticle* article){
            XCTAssertTrue(article != firstArticle, @"Expected object returned from 2nd fetch to not be identical to 1st.");
            assertThat(article, is(equalTo(firstArticle)));
            assertThat(@([article isDeeplyEqualToArticle:firstArticle]), isTrue());
        });
    });

    MWKArticle* savedArticle = [self.tempDataStore articleFromDiskWithTitle:dummyTitle];
    assertThat(savedArticle, is(equalTo(firstArticle)));
    assertThat(@([savedArticle isDeeplyEqualToArticle:firstArticle]), isTrue());
}

@end
