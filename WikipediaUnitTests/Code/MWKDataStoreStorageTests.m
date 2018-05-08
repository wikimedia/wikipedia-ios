#import <XCTest/XCTest.h>

#import "MWKArticleStoreTestCase.h"

@interface MWKDataStoreStorageTests : MWKArticleStoreTestCase

@end

@implementation MWKDataStoreStorageTests

- (void)testWriteReadArticle {
    XCTAssertNotNil([self.dataStore articleWithURL:self.articleURL], @"article stub can be loaded before we save it");

    MWKArticle *article;
    article = [[MWKArticle alloc] initWithURL:self.articleURL dataStore:self.dataStore dict:self.json0[@"mobileview"]];

    MWKArticle *article2;
    XCTAssertTrue([self.dataStore saveArticle:article error:nil]);
    XCTAssertNoThrow(article2 = [self.dataStore articleWithURL:self.articleURL], @"article can't be loaded after saving it");
    XCTAssertEqual(article, article2);

    XCTAssertNoThrow([self.dataStore addArticleToMemoryCache:article]);
    XCTAssertNoThrow(article2 = [self.dataStore articleWithURL:self.articleURL], @"article can't be loaded after saving it");
    XCTAssertEqualObjects(article, article2);
}

- (void)testArticleStoreSection0 {
    XCTAssertNoThrow([self.article importMobileViewJSON:self.json0[@"mobileview"]]);
    [self.article save:nil];

    MWKArticle *article;
    XCTAssertNoThrow(article = [self.dataStore articleWithURL:self.articleURL], @"article can be loaded after saving it");

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForArticleURL:self.articleURL] stringByAppendingPathComponent:@"Article.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:0 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:0 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.html"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertFalse([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.html"]]);
}

- (void)testArticleStoreSection1ToEnd {
    XCTAssertNoThrow([self.article importMobileViewJSON:self.json1[@"mobileview"]]);
    [self.article save:nil];

    MWKArticle *article;
    XCTAssertNoThrow(article = [self.dataStore articleWithURL:self.articleURL], @"article can be loaded after saving it");

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForArticleURL:self.articleURL] stringByAppendingPathComponent:@"Article.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:1 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:1 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.html"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.plist"]]);
    XCTAssertTrue([fm fileExistsAtPath:[[self.dataStore pathForSectionId:35 inArticleWithURL:self.articleURL] stringByAppendingPathComponent:@"Section.html"]]);
}

- (void)testArticleStoreReadSections {
    XCTAssertNoThrow([self.article importMobileViewJSON:self.json0[@"mobileview"]]);
    [self.article save:nil];

    MWKSectionList *sections = self.article.sections;
    XCTAssertNotNil(sections);

    XCTAssertEqual([sections count], 36);
}

/*
   // Can't store these alone
   - (void)testArticleStoreAnon
   {
    XCTAssertNil([self.dataStore articleWithTitle:self.title], @"article cannot be loaded before we save it");

    XCTAssertNoThrow([self.articleStore importMobileViewJSON:self.jsonAnon]);

    MWKArticle *article;
    XCTAssertNoThrow(article = [self.dataStore articleWithTitle:self.title], @"article can be loaded after saving it");
   }
 */

@end
