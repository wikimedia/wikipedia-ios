//
//  WMFArticleImageInjectionTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "XCTestCase+WMFBundleConvenience.h"
#import "NSBundle+TestAssets.h"
#import "WMFArticleParsing.h"

#import "MWKArticle.h"
#import "MWKImageList.h"
#import "MWKSectionList.h"
#import "MWKSection.h"

#import "MWKDataStore.h"

#import <BlocksKit/BlocksKit.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface WMFArticleImageInjectionTests : XCTestCase
@property MWKArticle* article;
@property MWKDataStore* dataStore;
@end

@implementation WMFArticleImageInjectionTests

- (void)setUp {
    [super setUp];
}

- (void)testImgTagReductionStartsWithImg {
    assertThat(WMFImgTagsFromHTML(@"<img src=\"foo\"><bla bla>"), is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionMultiple {
    assertThat(WMFImgTagsFromHTML(@"<img src=\"foo\"><bla bla><img src=\"foo\">"), is(equalTo(@"<img src=\"foo\"><img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithSpace {
    assertThat(WMFImgTagsFromHTML(@" <img src=\"foo\"><bla bla>"), is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithOtherTag {
    assertThat(WMFImgTagsFromHTML(@" <p>what</p> <img src=\"foo\"><bla bla>"), is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithOtherTagWithSpace {
    assertThat(WMFImgTagsFromHTML(@"<p>what</p> <img src=\"foo\"><bla bla>"), is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithOtherTagNoSpace {
    assertThat(WMFImgTagsFromHTML(@"<p>what</p><img src=\"foo\"><bla bla>"), is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionSpace {
    assertThat(WMFImgTagsFromHTML(@" "), is(equalTo(@"")));
}

- (void)testImgTagReductionEmptyString {
    assertThat(WMFImgTagsFromHTML(@""), is(equalTo(@"")));
}

- (void)testImgTagParsing {
    assertThat(WMFImgTagsFromHTML(@"<img src=\"foo\"></img>"), is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagParsingStripsOtherElements {
    assertThat(WMFImgTagsFromHTML(@"<img src=\"foo\"/><div/><img src=\"bar\"/>"),
               is(equalTo(@"<img src=\"foo\"/><img src=\"bar\"/>")));
}

- (void)testImgTagReductionNonHTMLString {
    assertThat(WMFImgTagsFromHTML(@"bla bla"), is(equalTo(@"")));
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        self.dataStore = mock([MWKDataStore class]);
        self.article = [[MWKArticle alloc] initWithTitle:nil dataStore:self.dataStore];

        [given([self.dataStore imageListWithArticle:anything() section:anything()])
         willReturn:[[MWKImageList alloc] initWithArticle:self.article section:nil]];

        NSParameterAssert(self.article.images);

        [self.article importMobileViewJSON:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

        for (int i = 0; i < self.article.sections.count; i++) {
            MWKSection* section = self.article.sections[i];
            WMFInjectArticleWithImagesFromSection(self.article, section.text, section.sectionId);
        }

        #warning TODO: assert proper number of image entries & sourceURLs
        assertThat(@(self.article.images.count), is(greaterThan(@0)));
    }];
}

@end
