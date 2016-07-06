//
//  MWKArticleEqualityChecks.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/12/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MWKArticle.h"
#import "MWKSectionList.h"
#import "MWKTitle.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKArticleEqualityCheckTests : XCTestCase

@end

@implementation MWKArticleEqualityCheckTests

- (void)testTwoArticlesWithSameTitlesAreEqual {
    MWKTitle* title = [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]];
    MWKArticle* foo =
        [[MWKArticle alloc] initWithTitle:title dataStore:nil];
    MWKArticle* foo2 =
        [[MWKArticle alloc] initWithTitle:title dataStore:nil];
    assertThat(foo, is(equalTo(foo2)));
}

- (void)testTwoArticlesWithSameTitleButDifferentFragmentAreEqual {
    MWKArticle* foo =
        [[MWKArticle alloc] initWithTitle:
         [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]] dataStore:nil];
    MWKArticle* fooWithBarFragment =
        [[MWKArticle alloc] initWithTitle:
         [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo#bar"]] dataStore:nil];
    assertThat(foo, is(equalTo(fooWithBarFragment)));
}

- (void)testTwoArticlesWithDifferentTitlesAreNotEqual {
    MWKArticle* foo =
        [[MWKArticle alloc] initWithTitle:
         [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Foo"]] dataStore:nil];
    MWKArticle* bar =
        [[MWKArticle alloc] initWithTitle:
         [[MWKTitle alloc] initWithURL:[NSURL URLWithString:@"//en.wikipedia.org/wiki/Bar"]] dataStore:nil];
    assertThat(foo, isNot(equalTo(bar)));
}

@end
