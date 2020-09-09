#import <XCTest/XCTest.h>
#import "NSString+WMFHTMLParsing.h"
#import "WMFTestFixtureUtilities.h"

@interface NSString_WMFHTMLParsingTests : XCTestCase

@end

@implementation NSString_WMFHTMLParsingTests

- (void)testSnippetFromTextWithCitaiton {
    XCTAssertEqualObjects([@"March 2011.[9][10] It was the first spacecraft to orbit Mercury.[7]" wmf_shareSnippetFromText], @"March 2011. It was the first spacecraft to orbit Mercury.");
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

- (void)testNewsNotificationHTMLRemoving {
    NSString *plaintext = @"Nothing happened";
    NSString *newsHTML = @"<!--May 19-->Nothing happened";
    NSString *newsPlainText = [newsHTML wmf_stringByRemovingHTML];
    XCTAssertEqualObjects(newsPlainText, plaintext);
    
    newsHTML = @"<!-- May 19 -->Nothing happened";
    newsPlainText = [newsHTML wmf_stringByRemovingHTML];
    XCTAssertEqualObjects(newsPlainText, plaintext);
}

- (void)testRemovingHTMLRetainsMinusEntity {
    //https://phabricator.wikimedia.org/T252047
    NSString *displayTitle = @"<i>B</i> &#8722; <i>L</i>";
    NSString *displayTitlePlainText = [displayTitle wmf_stringByRemovingHTML];
    XCTAssertEqualObjects(@"B − L", displayTitlePlainText);
    
    UIFont *standard = [UIFont systemFontOfSize:12];
    UIFont *italic = [UIFont italicSystemFontOfSize:12];
    NSMutableAttributedString *displayTitleAttributedString = [displayTitle wmf_attributedStringFromHTMLWithFont:standard boldFont:nil italicFont:italic boldItalicFont:nil color:nil linkColor:nil handlingLinks:NO handlingLists:NO handlingSuperSubscripts:NO tagMapping:nil additionalTagAttributes:nil];
    NSMutableAttributedString *attributedStringToCompare = [[NSMutableAttributedString alloc] initWithString:@"B − L"];
    [attributedStringToCompare addAttributes:@{NSFontAttributeName: italic} range:NSMakeRange(0, 1)];
    [attributedStringToCompare addAttributes:@{NSFontAttributeName: standard} range:NSMakeRange(1, 3)];
    [attributedStringToCompare addAttributes:@{NSFontAttributeName: italic} range:NSMakeRange(4, 1)];
    
    XCTAssertEqualObjects(displayTitleAttributedString, attributedStringToCompare);
    
}

@end
