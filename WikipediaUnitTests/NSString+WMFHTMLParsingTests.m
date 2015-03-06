//
//  NSString+ExtrasTests.m
//  Wikipedia
//
//  Created by Adam Baso on 3/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+WMFHTMLParsing.h"
#import "WikipediaAppUtils.h"
#import <hpple/TFHpple.h>

@interface NSString_WMFHTMLParsingTests : XCTestCase

@end

@implementation NSString_WMFHTMLParsingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTooShortSnippet {
    NSString *string = @"<p>Cat (meow) [cow] too short</p>";
    XCTAssertNil([string wmf_getStringSnippetWithoutHTML], @"Too short snippet non-nil after parsing");
}

- (void)testAdequateSnippet {
    NSString *string = @"<p>Dog (woof) [horse] adequately long string</p>";
    XCTAssertEqualObjects([string wmf_getStringSnippetWithoutHTML], @"Dog adequately long string");
}

@end
