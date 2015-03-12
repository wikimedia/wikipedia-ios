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
    NSString *string = @"<p>Dog (woof (w00t)) [horse] adequately long string historically 40 characters.</p>";
    XCTAssertEqualObjects([string wmf_getStringSnippetWithoutHTML],
                          @"Dog adequately long string historically 40 characters.");
}

- (void)testConsecutiveNewlinesCollapsing {
    NSString *string = @"\n\nHola\n\n";
    XCTAssertEqualObjects([string wmf_stringByCollapsingConsecutiveNewlines],
                          @"\nHola\n");
}

- (void)testNestedParenthesesRemoval {
        NSString *string = @"He(a(b(c(d)e)f)g)llo";
        XCTAssertEqualObjects([string wmf_stringByRecursivelyRemovingParenthesizedContent],
                              @"Hello");
}

- (void)testBracketedContentRemoval {
    NSString *string = @"J[aeio]ump";
    XCTAssertEqualObjects([string wmf_stringByRemovingBracketedContent],
                          @"Jump");
}

- (void)testRemovalOfSpaceBeforeCommaAndSemicolon
{
    NSString *string = @"fish , squids ; eagles  , crows";
    XCTAssertEqualObjects([string wmf_stringByRemovingWhiteSpaceBeforeCommasAndSemicolons],
                          @"fish, squids; eagles, crows");
}

- (void)testRemovalOfSpaceBeforePeriod {
    NSString *string = @"Yes . No 。 Maybe ． So ｡";
    XCTAssertEqualObjects([string wmf_stringByRemovingWhiteSpaceBeforePeriod],
                          @"Yes. No。 Maybe． So｡");
}

- (void)testConsecutiveSpacesCollapsing {
    NSString *string = @"          Metal          ";
    XCTAssertEqualObjects([string wmf_stringByCollapsingConsecutiveSpaces],
                          @" Metal ");
}

- (void)testRemovalOfLeadingOrTrailingSpacesNewlinesOrColons {
    NSString *string = @"\n          Syncopation:\n:";
    XCTAssertEqualObjects([string wmf_stringByRemovingLeadingOrTrailingSpacesNewlinesOrColons],
                          @"Syncopation");
}

@end
