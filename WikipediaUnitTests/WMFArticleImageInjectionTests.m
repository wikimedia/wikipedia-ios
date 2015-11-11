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

#import <BlocksKit/BlocksKit.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

@interface WMFArticleImageInjectionTests : XCTestCase
@property (nonatomic, strong) MWKArticle* article;
@property (nonatomic, strong) MWKDataStore* dataStore;
@property (nonatomic, strong) NSMutableArray* tempDataStores;
@end

@implementation WMFArticleImageInjectionTests

- (void)setUp {
    [super setUp];
    self.tempDataStores = [NSMutableArray new];
}

- (void)tearDown {
    [super tearDown];
    [self.tempDataStores makeObjectsPerformSelector:@selector(removeFolderAtBasePath)];
    self.tempDataStores = nil;
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        self.dataStore = [MWKDataStore temporaryDataStore];
        [self.tempDataStores addObject:self.dataStore];
        MWKTitle* title = [[MWKSite siteWithCurrentLocale] titleWithString:@"foo"];
        self.article = [[MWKArticle alloc] initWithTitle:title dataStore:self.dataStore];

        NSParameterAssert(self.article.images);

        [self.article importMobileViewJSON:[[self wmf_bundle] wmf_jsonFromContentsOfFile:@"Obama"][@"mobileview"]];

        [self.article importAndSaveImagesFromSectionHTML];

        #warning TODO: assert proper number of image entries & sourceURLs
        assertThat(@(self.article.images.count), is(greaterThan(@0)));
    }];
}

@end
