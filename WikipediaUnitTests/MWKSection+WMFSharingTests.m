//
//  MWKSection+WMFSharingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MWKSection+WMFSharing.h"

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
    self.section = [[MWKSection alloc] initWithArticle:nil
                                                  dict:@{
                        @"id": @0,
                        @"text": @"<p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>"
                    }];
    assertThat(self.section.shareSnippet, is(@"Dog adequately long string historically 40 characters."));
}

- (void)testSimpleSnippetIncludingTable {
    self.section = [[MWKSection alloc] initWithArticle:nil
                                                  dict:@{
                        @"id": @0,
                        @"text": @"<table><p>Foo</p></table><p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>"
                    }];
    assertThat(self.section.shareSnippet, is(@"Dog adequately long string historically 40 characters."));
}

@end
