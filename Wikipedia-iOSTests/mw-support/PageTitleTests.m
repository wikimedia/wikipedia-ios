//
//  PageTitleTests.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PageTitle.h"

@interface PageTitleTests : XCTestCase

@end

@implementation PageTitleTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testCreate
{
    NSString *ns = @"";
    NSString *text = @"Test-driven developent";
    PageTitle *title = [PageTitle titleFromNamespace:ns text:text];
    XCTAssert([title.namespace isEqualToString:ns], @"Title namespace should be what we passed in");
    XCTAssert([title.text isEqualToString:text], @"Title text should be what we passed in");
}

@end
