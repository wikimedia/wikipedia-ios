//
//  MWKSection+WMFSharingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKArticle.h"
#import "MWKSection.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSection_WMFSharingTests : XCTestCase
@property (nonatomic) MWKSection* section;
@end

@implementation MWKSection_WMFSharingTests

- (void)setUp {
    [super setUp];
}

- (void)testSimpleSnippet {
    MWKTitle* title     = [[MWKSite siteWithCurrentLocale] titleWithString:@"foo"];
    MWKArticle* article = [[MWKArticle alloc] initWithTitle:title dataStore:nil];
    self.section = [[MWKSection alloc] initWithArticle:article
                                                  dict:@{
                        @"id": @0,
                        @"text": @"<p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>"
                    }];
    assertThat([self.section shareSnippet], is(@"Dog adequately long string historically 40 characters."));
}

- (void)testSimpleSnippetIncludingTable {
    MWKTitle* title     = [[MWKSite siteWithCurrentLocale] titleWithString:@"foo"];
    MWKArticle* article = [[MWKArticle alloc] initWithTitle:title dataStore:nil];
    self.section = [[MWKSection alloc] initWithArticle:article
                                                  dict:@{
                        @"id": @0,
                        @"text": @"<table><p>Foo</p></table><p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>"
                    }];
    assertThat([self.section shareSnippet], is(@"Dog adequately long string historically 40 characters."));
}

@end
