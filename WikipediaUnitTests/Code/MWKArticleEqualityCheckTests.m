#import <XCTest/XCTest.h>
#import "MWKArticle.h"
#import "MWKSectionList.h"

@interface MWKArticleEqualityCheckTests : XCTestCase

@end

@implementation MWKArticleEqualityCheckTests

- (void)testTwoArticlesWithSameTitlesAreEqual {
    NSURL *url = [NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"];
    MWKArticle *foo =
        [[MWKArticle alloc] initWithURL:url
                              dataStore:nil];
    MWKArticle *foo2 =
        [[MWKArticle alloc] initWithURL:url
                              dataStore:nil];
    XCTAssert([foo isEqual:foo2]);
}

- (void)testTwoArticlesWithSameTitleButDifferentFragmentAreEqual {
    MWKArticle *foo =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]
                              dataStore:nil];
    MWKArticle *fooWithBarFragment =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo#bar"]
                              dataStore:nil];
    XCTAssert([foo isEqual:fooWithBarFragment]);
}

- (void)testTwoArticlesWithDifferentTitlesAreNotEqual {
    MWKArticle *foo =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]
                              dataStore:nil];
    MWKArticle *bar =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Bar"]
                              dataStore:nil];
    XCTAssert(![foo isEqual:bar]);
}

@end
