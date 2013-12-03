//
//  PageTitleTests.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MWPageTitle.h"

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
    
    // crazy hack for "tests not finished"
    [NSThread sleepForTimeInterval:1.0];
    NSLog(@"done");
    
    [super tearDown];
}

- (void)testCreate
{
    NSArray *dataSet = @[@{@"prefixed": @"Test-driven development",
                           @"ns": @"",
                           @"text": @"Test-driven development"},
                         @{@"prefixed": @"Talk:Test-driven development",
                           @"ns": @"Talk",
                           @"text": @"Test-driven development"}];
    for (NSDictionary *data in dataSet) {
        NSString *ns = data[@"ns"];;
        NSString *text = data[@"text"];
        
        MWPageTitle *title = [MWPageTitle titleFromNamespace:ns text:text];
        XCTAssertEqualObjects(title.namespace, ns, @"Title namespace check");
        XCTAssertEqualObjects(title.text, text, @"Title text check");
        XCTAssertEqualObjects(title.prefixedText, data[@"prefixed"], @"Prefixed text check");
    }
}

@end
