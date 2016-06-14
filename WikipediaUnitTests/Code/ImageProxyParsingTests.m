#import <XCTest/XCTest.h>

#import <OCHamcrest/OCHamcrest.h>
#import <BlocksKit/BlocksKit.h>

#import "NSString+WMFImageProxy.h"

@interface NSString (WMFImageProxyTesting)

- (NSString*)wmf_replaceURLsWithLocalhostProxyURLsInSrcsetValue:(NSString*)srcsetValue;

@end

@interface ImageProxyParsingTests : XCTestCase

@end

@implementation ImageProxyParsingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImgTagSrcUrlIsConvertedToProxyFormat {
    NSString* string =
        @"<img src=\"//test.png\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected =
        @"<img src=\"http://localhost:8080/imageProxy?originalSrc=//test.png\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testSrcsetValueWithSingleUrlIsConvertedToProxyFormat {
    NSString* string =
        @"//test2x.png 2x";

    string = [string wmf_replaceURLsWithLocalhostProxyURLsInSrcsetValue:string];

    NSString* expected =
        @"http://localhost:8080/imageProxy?originalSrc=//test2x.png 2x";

    assertThat(string, is(equalTo(expected)));
}

- (void)testSrcsetValueWithMultipleUrlsIsConvertedToProxyFormat {
    NSString* string =
        @"//test2x.png 2x, //test3x.png 3x";

    string = [string wmf_replaceURLsWithLocalhostProxyURLsInSrcsetValue:string];

    NSString* expected =
        @"http://localhost:8080/imageProxy?originalSrc=//test2x.png 2x, http://localhost:8080/imageProxy?originalSrc=//test3x.png 3x";

    assertThat(string, is(equalTo(expected)));
}

- (void)testBothSrcAndSrcsetUrlsAreConvertedToProxyFormat {
    NSString* string =
        @"<img src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected =
        @"<img src=\"http://localhost:8080/imageProxy?originalSrc=//test.png\" srcset=\"http://localhost:8080/imageProxy?originalSrc=//test2x.png 2x\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testNonImageTagSrcAndSrcsetAreUnchanged {
    NSString* string = @""
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testImageTagIsChangedButNonImageTagIsUnchanged {
    NSString* string = @""
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<img src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                         "<img src=\"http://localhost:8080/imageProxy?originalSrc=//test.png\" srcset=\"http://localhost:8080/imageProxy?originalSrc=//test2x.png 2x\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testAttributesOtherThanSrcAndSrcsetAreUnchanged {
    NSString* string = @""
                       "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" srcset=\"//test2x.png 2x\" width=\"128\" height=\"31\"/>";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<img alt=\"\" src=\"http://localhost:8080/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" srcset=\"http://localhost:8080/imageProxy?originalSrc=//test2x.png 2x\" width=\"128\" height=\"31\"/>";

    assertThat(string, is(equalTo(expected)));
}

- (void)testSrcUrlIsConvertedToProxyFormatWithOriginalUrlBeingPercentEncoded {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString* string = @""
                       "<img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/220px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<img src=\"http://localhost:8080/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%25C5%25BDeljezni%25C4%258Dki_most%252C_Mursko_Sredi%25C5%25A1%25C4%2587e_%2528Croatia%2529.1.jpg/220px-%25C5%25BDeljezni%25C4%258Dki_most%252C_Mursko_Sredi%25C5%25A1%25C4%2587e_%2528Croatia%2529.1.jpg\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testSrcsetUrlsAreConvertedToProxyFormatWithOriginalUrlsBeingPercentEncoded {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString* string = @""
                       "<img src=\"\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/330px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/440px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg 2x\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<img src=\"\" srcset=\"http://localhost:8080/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%25C5%25BDeljezni%25C4%258Dki_most%252C_Mursko_Sredi%25C5%25A1%25C4%2587e_%2528Croatia%2529.1.jpg/330px-%25C5%25BDeljezni%25C4%258Dki_most%252C_Mursko_Sredi%25C5%25A1%25C4%2587e_%2528Croatia%2529.1.jpg 1.5x, http://localhost:8080/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%25C5%25BDeljezni%25C4%258Dki_most%252C_Mursko_Sredi%25C5%25A1%25C4%2587e_%2528Croatia%2529.1.jpg/440px-%25C5%25BDeljezni%25C4%258Dki_most%252C_Mursko_Sredi%25C5%25A1%25C4%2587e_%2528Croatia%2529.1.jpg 2x\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testEmptySrcAndSrcAttributesAreUnchanged {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString* string = @""
                       "<img src=\"\" srcset=\"\">";

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<img src=\"\" srcset=\"\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testMultipleImageTagsAreChangedButNonImageTagsAreUnchanged {
    NSString* string = @""
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<img src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<img src=\"//testThis.png\" srcset=\"//testThis2x.png 2x\">"
    ;

    string = [string wmf_stringWithImgTagSrcAndSrcsetURLsChangedToLocalhostProxyURLs];

    NSString* expected = @""
                         "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                         "<img src=\"http://localhost:8080/imageProxy?originalSrc=//test.png\" srcset=\"http://localhost:8080/imageProxy?originalSrc=//test2x.png 2x\">"
                         "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                         "<img src=\"http://localhost:8080/imageProxy?originalSrc=//testThis.png\" srcset=\"http://localhost:8080/imageProxy?originalSrc=//testThis2x.png 2x\">"
    ;

    assertThat(string, is(equalTo(expected)));
}

@end
