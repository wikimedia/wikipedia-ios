#import <XCTest/XCTest.h>
#import "MWKTestCase.h"
#import "Wikipedia-Swift.h"

@interface ImageSchemeParsingTests : MWKTestCase
@property (nonatomic, copy) NSString *galleryAttribute;
@property (nonatomic) NSUInteger imageSize;
@end

@implementation ImageSchemeParsingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.imageSize = 640;
    self.galleryAttribute = @"data-image-gallery=\"true\"";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImgTagSrcUrlIsConvertedToSchemeFormat {
    NSString *string =
        @"<img src=\"//test.png\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @"<img src=\"wmfapp://test.png\">";

    XCTAssertEqualObjects(string, expected);
}

- (void)testSrcIsSetToOriginal {
    self.imageSize = 640;
    NSString *string =
        @"<img alt=\"A young boy (preteen), a younger girl (toddler), a woman (about age thirty) and a man (in his mid-fifties) sit on a lawn wearing contemporary c.-1970 attire. The adults wear sunglasses and the boy wears sandals.\" src=\"//upload.wikimedia.org/wikipedia/en/thumb/3/33/Ann_Dunham_with_father_and_children.jpg/220px-Ann_Dunham_with_father_and_children.jpg\" width=\"220\" height=\"146\" class=\"thumbimage\" srcset=\"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg 1.5x, //upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg 2x\" data-file-width=\"320\" data-file-height=\"212\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = [NSString stringWithFormat:@"<img alt=\"A young boy (preteen), a younger girl (toddler), a woman (about age thirty) and a man (in his mid-fifties) sit on a lawn wearing contemporary c.-1970 attire. The adults wear sunglasses and the boy wears sandals.\" src=\"wmfapp://upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg\" width=\"220\" height=\"146\" class=\"thumbimage\" data-srcset-disabled=\"//upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg 1.5x, //upload.wikimedia.org/wikipedia/en/3/33/Ann_Dunham_with_father_and_children.jpg 2x\" data-file-width=\"320\" data-file-height=\"212\" %@>", self.galleryAttribute];

    XCTAssertEqualObjects(string, expected);
}

- (void)testSrcIsScaled {
    self.imageSize = 640;
    NSString *string =
        @"<img alt=\"Obama about to take a shot while three other players look at him. One of those players is holding is arms up in an attempt to block Obama.\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/170px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg\" width=\"170\" height=\"255\" class=\"thumbimage\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/255px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/340px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg 2x\" data-file-width=\"2333\" data-file-height=\"3500\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = [NSString stringWithFormat:@"<img alt=\"Obama about to take a shot while three other players look at him. One of those players is holding is arms up in an attempt to block Obama.\" src=\"wmfapp://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/%llupx-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg\" width=\"170\" height=\"255\" class=\"thumbimage\" data-srcset-disabled=\"//upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/255px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg/340px-Barack_Obama_playing_basketball_with_members_of_Congress_and_Cabinet_secretaries_2.jpg 2x\" data-file-width=\"2333\" data-file-height=\"3500\" %@>", (unsigned long long)self.imageSize, self.galleryAttribute];

    XCTAssertEqualObjects(string, expected);
}

- (void)testSVGSrcIsScaledBeyondDataFileWidth {
    self.imageSize = 800;
    NSString *string =
        @"<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/300px-US_Employment_Statistics.svg.png\" width=\"300\" height=\"200\" class=\"thumbimage\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/450px-US_Employment_Statistics.svg.png 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/600px-US_Employment_Statistics.svg.png 2x\" data-file-width=\"720\" data-file-height=\"480\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = [NSString stringWithFormat:@"<img alt=\"\" src=\"wmfapp://upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/%llupx-US_Employment_Statistics.svg.png\" width=\"300\" height=\"200\" class=\"thumbimage\" data-srcset-disabled=\"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/450px-US_Employment_Statistics.svg.png 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/600px-US_Employment_Statistics.svg.png 2x\" data-file-width=\"720\" data-file-height=\"480\" %@>", (unsigned long long)self.imageSize, self.galleryAttribute];

    XCTAssertEqualObjects(string, expected);
}

- (void)testSVGSrcIsScaledWhenPossible {
    self.imageSize = 640;
    NSString *string =
        @"<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/300px-US_Employment_Statistics.svg.png\" width=\"300\" height=\"200\" class=\"thumbimage\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/450px-US_Employment_Statistics.svg.png 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/600px-US_Employment_Statistics.svg.png 2x\" data-file-width=\"720\" data-file-height=\"480\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = [NSString stringWithFormat:@"<img alt=\"\" src=\"wmfapp://upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/%llupx-US_Employment_Statistics.svg.png\" width=\"300\" height=\"200\" class=\"thumbimage\" data-srcset-disabled=\"//upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/450px-US_Employment_Statistics.svg.png 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/2/25/US_Employment_Statistics.svg/600px-US_Employment_Statistics.svg.png 2x\" data-file-width=\"720\" data-file-height=\"480\" data-image-gallery=\"true\">", (unsigned long long)self.imageSize];

    XCTAssertEqualObjects(string, expected);
}

- (void)testNonImageTagSrcAndSrcsetAreUnchanged {
    NSString *string = @""
                        "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @""
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    XCTAssertEqualObjects(string, expected);
}

- (void)testImageTagIsChangedButNonImageTagIsUnchanged {
    NSString *string = @""
                        "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                        "<img src=\"//test.png\" srcset=\"//test2x.png 2x\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @""
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                          "<img src=\"wmfapp://test.png\" data-srcset-disabled=\"//test2x.png 2x\">";

    XCTAssertEqualObjects(string, expected);
}

- (void)testAttributesOtherThanSrcAndSrcsetAreUnchanged {
    NSString *string = @""
                        "<img alt=\"\" src=\"//upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" srcset=\"//test2x.png 2x\" width=\"128\" height=\"31\"/>";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @""
                          "<img alt=\"\" src=\"wmfapp://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Barack_Obama_signature.svg/128px-Barack_Obama_signature.svg.png\" data-srcset-disabled=\"//test2x.png 2x\" width=\"128\" height=\"31\"/>";

    XCTAssertEqualObjects(string, expected);
}

- (void)testSrcUrlIsConvertedToSchemeFormatWithOriginalUrlBeingPercentEncoded {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString *string = @""
                        "<img src=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/220px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @""
                          "<img src=\"wmfapp://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/220px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg\">";

    XCTAssertEqualObjects(string, expected);
}

- (void)testSrcsetUrlsAreDisabledWithOriginalUrlsBeingPercentEncoded {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString *string = @""
                        "<img src=\"\" srcset=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/330px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg/440px-%C5%BDeljezni%C4%8Dki_most%2C_Mursko_Sredi%C5%A1%C4%87e_%28Croatia%29.1.jpg 2x\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = [NSString stringWithFormat:@""
                                                     "<img src=\"\" data-srcset-disabled=\"//upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg/330px-%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg 1.5x, //upload.wikimedia.org/wikipedia/commons/thumb/d/dd/%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg/440px-%%C5%%BDeljezni%%C4%%8Dki_most%%2C_Mursko_Sredi%%C5%%A1%%C4%%87e_%%28Croatia%%29.1.jpg 2x\">"];

    XCTAssertEqualObjects(string, expected);
}

- (void)testEmptySrcAndSrcAttributesAreUnchanged {
    // From: https://en.wikipedia.org/wiki/Bridge
    NSString *string = @""
                        "<img src=\"\" srcset=\"\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @""
                          "<img src=\"\" data-srcset-disabled=\"\">";

    XCTAssert([string isEqualToString:expected]);
}

- (void)testMultipleImageTagsAreChangedButNonImageTagsAreUnchanged {
    NSString *string = @""
                        "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                        "<img src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                        "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                        "<img src=\"//testThis.png\" srcset=\"//testThis2x.png 2x\">";

    string = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:string withBaseURL:nil targetImageWidth:self.imageSize];

    NSString *expected = @""
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                          "<img src=\"wmfapp://test.png\" data-srcset-disabled=\"//test2x.png 2x\">"
                          "<someothertag src=\"//test.png\" srcset=\"//test2x.png 2x\">"
                          "<img src=\"wmfapp://testThis.png\" data-srcset-disabled=\"//testThis2x.png 2x\">";
    ;

    XCTAssertEqualObjects(string, expected);
}

- (void)testObamaArticleImageSchemeSubstitutionCount {
    NSString *allObamaHTMLWithImageTagsChanged = [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:[self allObamaHTML] withBaseURL:self.obamaBaseURL targetImageWidth:self.imageSize];
    NSArray *allObamaHTMLSplitOnImageScheme = [allObamaHTMLWithImageTagsChanged componentsSeparatedByString:@"wmfapp"];
    NSLog(@"allObamaHTMLSplitOnImageScheme count = %lu", (unsigned long)allObamaHTMLSplitOnImageScheme.count);
    XCTAssertEqual(allObamaHTMLSplitOnImageScheme.count, 107);
}

- (void)testPerformanceOfImageTagParsing {
    //initial run compiles regexes
    [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:@"Small sample string <img alt=\"Example.jpg\" src=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a9/Example.jpg/20px-Example.jpg\" width=\"20\" height=\"22\" srcset=\"//upload.wikimedia.org/wikipedia/en/thumb/a/a9/Example.jpg/30px-Example.jpg 1.5x, //upload.wikimedia.org/wikipedia/en/thumb/a/a9/Example.jpg/40px-Example.jpg 2x\" data-file-width=\"275\" data-file-height=\"297\"> and stuff." withBaseURL:self.obamaBaseURL targetImageWidth:self.imageSize];
    [self measureBlock:^{
        [WMFArticleJSONCompilationHelper stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:[self allObamaHTML] withBaseURL:self.obamaBaseURL targetImageWidth:self.imageSize];
    }];
}

@end
