#import <XCTest/XCTest.h>

#import "MWKArticle.h"
#import "MWKSectionList.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

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
    assertThat(foo, is(equalTo(foo2)));
}

- (void)testTwoArticlesWithSameTitleButDifferentFragmentAreEqual {
    MWKArticle *foo =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]
                              dataStore:nil];
    MWKArticle *fooWithBarFragment =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo#bar"]
                              dataStore:nil];
    assertThat(foo, is(equalTo(fooWithBarFragment)));
}

- (void)testTwoArticlesWithDifferentTitlesAreNotEqual {
    MWKArticle *foo =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]
                              dataStore:nil];
    MWKArticle *bar =
        [[MWKArticle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Bar"]
                              dataStore:nil];
    assertThat(foo, isNot(equalTo(bar)));
}

@end
