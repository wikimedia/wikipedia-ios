#import <XCTest/XCTest.h>

#import <OCHamcrest/OCHamcrest.h>
#import <BlocksKit/BlocksKit.h>

#import "WMFProxyServer.h"


@interface WMFProxyServer (Testing)
- (NSURL*)   baseURL;
@end

@interface ImageProxyParsingTests : XCTestCase
@property (nonatomic, copy) NSString* baseURLString;
@property (nonatomic, strong) WMFProxyServer* proxyServer;
@end

@implementation ImageProxyParsingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.proxyServer   = [WMFProxyServer sharedProxyServer];
    self.baseURLString = self.proxyServer.baseURL.absoluteString;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImgTagSrcUrlIsConvertedToProxyFormat {
    NSString* string =
        @"<img src=\"//test.png\">";

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];

    NSString* expected =
        [NSString stringWithFormat:@"<img src=\"%@/imageProxy?originalSrc=//test.png\">", self.baseURLString];

    assertThat(string, is(equalTo(expected)));
}


- (void)testNonImageTagSrcAndSrcsetAreUnchanged {
    NSString* string = @""
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];

    NSString* expected = @""
                         "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testImageTagIsChangedButNonImageTagIsUnchanged {
    NSString* string = @""
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<img src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];

    NSString* expected = [NSString stringWithFormat:@""
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                          "<img src=\"%@/imageProxy?originalSrc=//test.png\" data-srcset-disabled=\"//test2x.png 2x\">", self.baseURLString];

    assertThat(string, is(equalTo(expected)));
}

- (void)testAttributesOtherThanSrcAndSrcsetAreUnchanged {
    NSString* string = @""
                       "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" srcset=\"//test2x.png 2x\" width=\"128\" height=\"31\"/>";

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];

    NSString* expected = [NSString stringWithFormat:@""
                          "<img alt=\"\" src=\"%@/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" data-srcset-disabled=\"//test2x.png 2x\" width=\"128\" height=\"31\"/>", self.baseURLString];

    assertThat(string, is(equalTo(expected)));
}

- (void)testSrcUrlIsConvertedToProxyFormatWithOriginalUrlBeingPercentEncoded {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString* string = @""
                       "<img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/220px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg\">";

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];;

    NSString* expected = [NSString stringWithFormat:@""
                          "<img src=\"%@/imageProxy?originalSrc=//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%%25C5%%25BDeljezni%%25C4%%258Dki_most%%252C_Mursko_Sredi%%25C5%%25A1%%25C4%%2587e_%%2528Croatia%%2529.1.jpg/220px-%%25C5%%25BDeljezni%%25C4%%258Dki_most%%252C_Mursko_Sredi%%25C5%%25A1%%25C4%%2587e_%%2528Croatia%%2529.1.jpg\">", self.baseURLString];

    assertThat(string, is(equalTo(expected)));
}

- (void)testSrcsetUrlsAreDisabledWithOriginalUrlsBeingPercentEncoded {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString* string = @""
    "<img src=\"\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/330px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/440px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg 2x\">";
    
    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];;
    
    NSString* expected = [NSString stringWithFormat:@""
                          "<img src=\"\" data-srcset-disabled=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg/330px-%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg/440px-%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg 2x\">"];
    
    assertThat(string, is(equalTo(expected)));
}

- (void)testEmptySrcAndSrcAttributesAreUnchanged {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString* string = @""
                       "<img src=\"\" srcset=\"\">";

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];;

    NSString* expected = @""
                         "<img src=\"\" data-srcset-disabled=\"\">";

    assertThat(string, is(equalTo(expected)));
}

- (void)testMultipleImageTagsAreChangedButNonImageTagsAreUnchanged {
    NSString* string = @""
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<img src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                       "<img src=\"//testThis.png\" srcset=\"//testThis2x.png 2x\">"
    ;

    string = [self.proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string];;

    NSString* expected = [NSString stringWithFormat:@""
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                          "<img src=\"%@/imageProxy?originalSrc=//test.png\" data-srcset-disabled=\"//test2x.png 2x\">"
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                          "<img src=\"%@/imageProxy?originalSrc=//testThis.png\" data-srcset-disabled=\"//testThis2x.png 2x\">", self.baseURLString, self.baseURLString];
    ;

    assertThat(string, is(equalTo(expected)));
}

@end
