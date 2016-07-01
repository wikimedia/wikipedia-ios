//
//  MWKSection+HTMLImageParsingTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/11/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface MWKSection_HTMLImageParsingTests : XCTestCase

@end

@implementation MWKSection_HTMLImageParsingTests




//TODO: hook these tests back up to the imgTagsOnlyFromHTMLString method - move them to the WMFImageTagParserTests.m file




/*
- (void)testImgTagReductionStartsWithImg {
    assertThat([@"<img src=\"foo\"><bla bla>" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionMultiple {
    assertThat([@"<img src=\"foo\"><bla bla><img src=\"foo\">" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\"><img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithSpace {
    assertThat([@" <img src=\"foo\"><bla bla>" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithOtherTag {
    assertThat([@" <p>what</p> <img src=\"foo\"><bla bla>" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithOtherTagWithSpace {
    assertThat([@"<p>what</p> <img src=\"foo\"><bla bla>" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionStartsWithOtherTagNoSpace {
    assertThat([@"<p>what</p><img src=\"foo\"><bla bla>" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagReductionSpace {
    assertThat([@" " wmf_stringBySelectingHTMLImageTags], is(equalTo(@"")));
}

- (void)testImgTagReductionEmptyString {
    assertThat([@"" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"")));
}

- (void)testImgTagParsing {
    assertThat([@"<img src=\"foo\"></img>" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"<img src=\"foo\">")));
}

- (void)testImgTagParsingStripsOtherElements {
    assertThat([@"<img src=\"foo\"/><div/><img src=\"bar\"/>" wmf_stringBySelectingHTMLImageTags],
               is(equalTo(@"<img src=\"foo\"/><img src=\"bar\"/>")));
}

- (void)testImgTagReductionNonHTMLString {
    assertThat([@"bla bla" wmf_stringBySelectingHTMLImageTags], is(equalTo(@"")));
}
*/
 
@end
