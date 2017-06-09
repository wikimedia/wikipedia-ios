#import <XCTest/XCTest.h>

#import "MWKTestCase.h"
#import "MWKDataStore+TemporaryDataStore.h"

@interface MWKDataStorePathTests : MWKTestCase {
    NSURL *siteURL;
    NSURL *articleURL;
    NSURL *articleURLUnicode;
    NSURL *articleURLEvil;
    NSURL *articleURLForbiddenCity;
    NSDictionary *json;
    MWKArticle *article;
    MWKDataStore *dataStore;
    NSString *basePath;
}

@end

@implementation MWKDataStorePathTests

- (void)setUp {
    [super setUp];
    siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
    articleURL = [siteURL wmf_URLWithTitle:@"San Francisco"];
    articleURLUnicode = [siteURL wmf_URLWithTitle:@"Éclair"];
    articleURLEvil = [siteURL wmf_URLWithTitle:@"AT&T/SBC \"merger\""];

    articleURLForbiddenCity = [siteURL wmf_URLWithTitle:@"Forbidden City"];

    dataStore = [MWKDataStore temporaryDataStore];
    basePath = dataStore.basePath;

    json = [self loadJSON:@"section0"];
    article = [[MWKArticle alloc] initWithURL:articleURL dataStore:dataStore dict:json[@"mobileview"]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBasePath {
    XCTAssertEqualObjects(dataStore.basePath, basePath);
}

- (void)testSitesPath {
    XCTAssertEqualObjects([dataStore pathForSites], [basePath stringByAppendingPathComponent:@"sites"]);
}

- (void)testSitePath {
    XCTAssertEqualObjects([dataStore pathForDomainInURL:siteURL], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en"]);
}

- (void)testArticlesPath {
    XCTAssertEqualObjects([dataStore pathForArticlesInDomainFromURL:siteURL], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles"]);
}

- (void)testTitlePath {
    XCTAssertEqualObjects([dataStore pathForArticleURL:articleURL], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco"]);
}

- (void)testTitleUnicodePath {
    XCTAssertEqualObjects([dataStore pathForArticleURL:articleURLUnicode], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/Éclair"]);
}

- (void)testTitleEvilPath {
    XCTAssertEqualObjects([dataStore pathForArticleURL:articleURLEvil], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/AT&T%2FSBC_\"merger\""]);
}

- (void)testArticlePath {
    XCTAssertEqualObjects([dataStore pathForArticle:article], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco"]);
}

- (void)testSectionsPath {
    XCTAssertEqualObjects([dataStore pathForSectionsInArticleWithURL:article.url], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco/sections"]);
}

- (void)testSectionPath {
    MWKSection *section0 = [[MWKSection alloc] initWithArticle:article dict:json[@"mobileview"][@"sections"][0]];
    MWKSection *section35 = [[MWKSection alloc] initWithArticle:article dict:json[@"mobileview"][@"sections"][35]];

    XCTAssertEqualObjects([dataStore pathForSection:section0], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco/sections/0"]);
    XCTAssertEqualObjects([dataStore pathForSection:section35], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco/sections/35"]);
}

- (void)testSectionIdPath {
    XCTAssertEqualObjects([dataStore pathForSectionId:0 inArticleWithURL:articleURL], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco/sections/0"]);
    XCTAssertEqualObjects([dataStore pathForSectionId:35 inArticleWithURL:articleURL], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/San_Francisco/sections/35"]);
}

- (void)testImagesPath {
    XCTAssertEqualObjects([dataStore pathForImagesWithArticleURL:articleURLForbiddenCity], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/Forbidden_City/Images"]);
}

- (void)testImagePathUnicode {
    NSString *urlForbiddenCityImage = @"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/%E5%8C%97%E4%BA%AC%E6%95%85%E5%AE%AB12.JPG/440px-%E5%8C%97%E4%BA%AC%E6%95%85%E5%AE%AB12.JPG";

    XCTAssertEqualObjects([dataStore pathForImageURL:urlForbiddenCityImage forArticleURL:articleURLForbiddenCity], [basePath stringByAppendingPathComponent:@"sites/wikipedia.org/en/articles/Forbidden_City/Images/440px-北京故宫12.JPG"]);
}

@end
