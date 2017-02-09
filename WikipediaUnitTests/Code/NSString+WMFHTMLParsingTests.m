#import <XCTest/XCTest.h>
#import "NSString+WMFHTMLParsing.h"
#import <hpple/TFHpple.h>
#import "WMFTestFixtureUtilities.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface NSString_WMFHTMLParsingTests : XCTestCase

@end

@implementation NSString_WMFHTMLParsingTests

- (void)testSnippetFromTextWithCitaiton {
    assertThat([@"March 2011.[9][10] It was the first spacecraft to orbit Mercury.[7]" wmf_shareSnippetFromText],
               is(@"March 2011. It was the first spacecraft to orbit Mercury."));
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

- (void)testRemovalOfSpaceBeforeCommaAndSemicolon {
    NSString *string = @"fish , squids ; eagles  , crows";
    XCTAssertEqualObjects([string wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes],
                          @"fish, squids; eagles, crows");
}

- (void)testRemovalOfSpaceBeforePeriod {
    NSString *string = @"Yes . No 。 Maybe ． So ｡";
    XCTAssertEqualObjects([string wmf_stringByRemovingWhiteSpaceBeforePeriodsCommasSemicolonsAndDashes],
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

- (void)testPunctuationAwareWhitespaceCollapsingCommasSemicolonsAndPeriods {
    NSString *string = @"trim space before commas , semicolons ; and periods .";
    XCTAssertEqualObjects([string wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation], @"trim space before commas, semicolons; and periods.");
}

- (void)testPunctuationAwareWhitespaceCollapsingLeadingAndTrailingWhitespace {
    NSString *string = @"   \t trim leading and trailing whitespace ok? \n \t";
    XCTAssertEqualObjects([string wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation], @"trim leading and trailing whitespace ok?");
}

- (void)testPunctuationAwareWhitespaceCollapsingReduceWhitespaceAroundParenthesisOrBrackets {
    NSString *string = @"collapse but do not (   no!   ) completely remove space around parenthesis or brackets [ \t brackets!\t]";
    XCTAssertEqualObjects([string wmf_getCollapsedWhitespaceStringAdjustedForTerminalPunctuation], @"collapse but do not ( no! ) completely remove space around parenthesis or brackets [ brackets! ]");
}

- (void)testAllWhitepacesCollapsing {
    NSString *string = @"  \t \n This   should  \t\t not have \t\n  so much space!   \n\n\t";
    XCTAssertEqualObjects([string wmf_stringByCollapsingAllWhitespaceToSingleSpaces],
                          @" This should not have so much space! ");
}

@end
