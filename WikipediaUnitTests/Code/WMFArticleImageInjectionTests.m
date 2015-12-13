//
//  WMFArticleImageInjectionTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKArticle+HTMLImageImport.h"
#import "MWKSection+HTMLImageExtraction.h"
#import "WMFTestFixtureUtilities.h"

#import "MWKArticle.h"
#import "MWKImageList.h"
#import "MWKSectionList.h"
#import "MWKSection.h"
#import "MWKDataStore+TemporaryDataStore.h"

#import <hpple/TFHpple.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface WMFArticleImageInjectionTests : XCTestCase
@property (nonatomic, strong) MWKDataStore* dataStore;
@end

@implementation WMFArticleImageInjectionTests

- (void)tearDown {
    [super tearDown];
    [self.dataStore removeFolderAtBasePath];
}

- (void)testExtractsSrcAndSrcsetImagesFromFixture {
    self.dataStore = [MWKDataStore temporaryDataStore];
    TFHppleElement* obamaElement =
        [[TFHpple hppleWithHTMLData:[[self wmf_bundle] wmf_dataFromContentsOfFile:@"ObamaImageElement" ofType:@"html"]]
         peekAtSearchWithXPathQuery:@"//html/body/*"];
    NSParameterAssert(obamaElement);

    MWKArticle* article = [[MWKArticle alloc] initWithTitle:[MWKTitle random] dataStore:self.dataStore];

    [article importMobileViewJSON:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

    [article importAndSaveImagesFromElement:obamaElement intoSection:0];

    id (^ hasSourceURLWithPrefix)(NSUInteger sizePrefix) = ^(NSUInteger sizePrefix) {
        static NSString* expectedSourceURLFormat =
            @"//upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/%dpx-President_Barack_Obama.jpg";
        return hasProperty(WMF_SAFE_KEYPATH(MWKImage.new, sourceURLString),
                           [NSString stringWithFormat:expectedSourceURLFormat, sizePrefix]);
    };

    id (^ withMatchingPrefixAndScale)(NSUInteger sizePrefix, float scale) = ^(NSUInteger sizePrefix, float scale){
        return allOf(hasSourceURLWithPrefix(sizePrefix),
                     hasProperty(WMF_SAFE_KEYPATH(MWKImage.new, width),
                                 @(220 * scale)),
                     hasProperty(WMF_SAFE_KEYPATH(MWKImage.new, height),
                                 @(275 * scale)),
                     nil);
    };

    NSArray<MWKImage*>* savedImages = [article.images.entries bk_map:^MWKImage*(NSString* urlString) {
        return [self.dataStore imageWithURL:urlString article:article];
    }];

    // article image list should also contain the lead image due to importMobileViewJSON
    assertThat(savedImages, hasItems(hasSourceURLWithPrefix(640),
                                     withMatchingPrefixAndScale(220, 1.0),
                                     withMatchingPrefixAndScale(330, 1.0),
                                     withMatchingPrefixAndScale(440, 2.0),
                                     nil));

    // first section's image list should also have the images from the element (same as article image list, minus lead image)
    assertThat(article.sections[0].images.entries,
               is(equalTo([article.images.entries subarrayWithRange:NSMakeRange(1, article.images.count - 1)])));
}

- (void)testExcludesElementsBelowSizeThreshold {
    self.dataStore = [MWKDataStore temporaryDataStore];
    TFHppleElement* smallImageElement =
        [[TFHpple hppleWithHTMLData:[
              @"<html><body>"
              "<img src=\"//upload.wikimedia.org/icon.jpg\" width=10 height=10/>"
              "</body></html>"
              dataUsingEncoding:NSUTF8StringEncoding]]
         peekAtSearchWithXPathQuery:@"//html/body/*"];
    NSParameterAssert(smallImageElement);

    MWKArticle* article = [[MWKArticle alloc] initWithTitle:[MWKTitle random] dataStore:self.dataStore];

    [article importAndSaveImagesFromElement:smallImageElement intoSection:kMWKArticleSectionNone];

    assertThat(article.images.entries, isEmpty());
}

- (void)testImportsAllExpectedImagesFromFixture {
        self.dataStore = [MWKDataStore temporaryDataStore];

        MWKArticle* article = [[MWKArticle alloc] initWithTitle:[MWKTitle random] dataStore:self.dataStore];

        [article importMobileViewJSON:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

        [article importAndSaveImagesFromSectionHTML];

        // expected number is observed & recorded,
        assertThat(@(article.images.count), is(@95));
        [self.dataStore removeFolderAtBasePath];
}

@end
