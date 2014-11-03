//
//  MWKDataStoreTests.m
//  MediaWikiKit
//
//  Created by Brion on 10/21/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKTestCase.h"

@interface MWKDataStorePathTests : MWKTestCase {
    MWKSite *site;
    MWKTitle *title;
    MWKTitle *titleUnicode;
    MWKTitle *titleEvil;
    MWKTitle *titleForbiddenCity;
    NSDictionary *json;
    MWKArticle *article;
    MWKDataStore *dataStore;
}

@end

@implementation MWKDataStorePathTests

- (void)setUp {
    [super setUp];
    site = [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:@"en"];
    title = [site titleWithString:@"San Francisco"];
    titleUnicode = [site titleWithString:@"Éclair"];
    titleEvil = [site titleWithString:@"AT&T/SBC \"merger\""];

    titleForbiddenCity = [site titleWithString:@"Forbidden City"];
    
    json = [self loadJSON:@"section0"];
    article = [[MWKArticle alloc] initWithTitle:title dict:json[@"mobileview"]];

    dataStore = [[MWKDataStore alloc] initWithBasePath:@"/"];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBasePath {
    XCTAssertEqualObjects(dataStore.basePath, @"/");
}

- (void)testSitesPath {
    XCTAssertEqualObjects([dataStore pathForSites], @"/sites");
}

- (void)testSitePath {
    XCTAssertEqualObjects([dataStore pathForSite:site], @"/sites/wikipedia.org/en");
}

- (void)testArticlesPath {
    XCTAssertEqualObjects([dataStore pathForArticlesWithSite:site], @"/sites/wikipedia.org/en/articles");
}

- (void)testTitlePath {
    XCTAssertEqualObjects([dataStore pathForTitle:title], @"/sites/wikipedia.org/en/articles/San_Francisco");
}

- (void)testTitleUnicodePath {
    XCTAssertEqualObjects([dataStore pathForTitle:titleUnicode], @"/sites/wikipedia.org/en/articles/%C3%89clair");
}

- (void)testTitleEvilPath {
    XCTAssertEqualObjects([dataStore pathForTitle:titleEvil], @"/sites/wikipedia.org/en/articles/AT%26T%2FSBC_%22merger%22");
}

- (void)testArticlePath {
    XCTAssertEqualObjects([dataStore pathForArticle:article], @"/sites/wikipedia.org/en/articles/San_Francisco");
}

- (void)testSectionsPath {
    XCTAssertEqualObjects([dataStore pathForSectionsWithTitle:article.title], @"/sites/wikipedia.org/en/articles/San_Francisco/sections");
}

- (void)testSectionPath {
    MWKSection *section0 = [[MWKSection alloc] initWithArticle:article dict:json[@"mobileview"][@"sections"][0]];
    MWKSection *section35 = [[MWKSection alloc] initWithArticle:article dict:json[@"mobileview"][@"sections"][35]];

    XCTAssertEqualObjects([dataStore pathForSection:section0], @"/sites/wikipedia.org/en/articles/San_Francisco/sections/section0");
    XCTAssertEqualObjects([dataStore pathForSection:section35], @"/sites/wikipedia.org/en/articles/San_Francisco/sections/section35");
}

- (void)testSectionIdPath {
    XCTAssertEqualObjects([dataStore pathForSectionId:0 title:title], @"/sites/wikipedia.org/en/articles/San_Francisco/sections/section0");
    XCTAssertEqualObjects([dataStore pathForSectionId:35 title:title], @"/sites/wikipedia.org/en/articles/San_Francisco/sections/section35");
}

- (void)testImagesPath {
    XCTAssertEqualObjects([dataStore pathForImagesWithTitle:titleForbiddenCity], @"/sites/wikipedia.org/en/articles/Forbidden_City/Images");
}

- (void)testImagePathUnicode {
    NSString *urlForbiddenCityImage = @"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/%E5%8C%97%E4%BA%AC%E6%95%85%E5%AE%AB12.JPG/440px-%E5%8C%97%E4%BA%AC%E6%95%85%E5%AE%AB12.JPG";

    XCTAssertEqualObjects([dataStore pathForImageURL:urlForbiddenCityImage title:titleForbiddenCity], @"/sites/wikipedia.org/en/articles/Forbidden_City/Images/wikipedia:commons:thumb:e:e6:%E5%8C%97%E4%BA%AC%E6%95%85%E5%AE%AB12.JPG:440px-%E5%8C%97%E4%BA%AC%E6%95%85%E5%AE%AB12.JPG");
}

@end
