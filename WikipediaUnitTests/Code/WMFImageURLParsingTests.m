#import <XCTest/XCTest.h>
#import "WMFImageURLParsing.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

@interface WMFImageURLParsingTests : XCTestCase

@end

@implementation WMFImageURLParsingTests

- (NSCharacterSet *)allowedCharacters {
    NSMutableCharacterSet *characterSet = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet URLHostAllowedCharacterSet]];
    [characterSet addCharactersInString:@":"];
    return characterSet;
}

- (void)testNoPrefixExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg")));
}

- (void)testImageWithOneExtensionExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg")));
}

- (void)testImageWithTwoExtensionsExample {
    NSString *testURL = @"http://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Access_to_drinking_water_in_third_world.svg/320px-Access_to_drinking_water_in_third_world.svg.png";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Access_to_drinking_water_in_third_world.svg")));
}

- (void)testImageWithPeriodInFileNameExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURL),
               is(equalTo(@"Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg")));
}

- (void)testNormalizedImageWithPeriodInFileNameExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg";
    NSString *normalized = WMFParseUnescapedNormalizedImageNameFromSourceURL(testURL);
    assertThat(normalized,
               is(equalTo(@"Claude Monet, 1870, Le port de Trouville (Breakwater at Trouville, Low Tide), oil on canvas, 54 x 65.7 cm, Museum of Fine Arts, Budapest.jpg")));
}

- (void)testNormalizedImageWithPeriodInFileNameFromURLExample {
    NSURL *testURL = [NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg"];
    NSString *normalized = WMFParseUnescapedNormalizedImageNameFromSourceURL(testURL);
    assertThat(normalized,
               is(equalTo(@"Claude Monet, 1870, Le port de Trouville (Breakwater at Trouville, Low Tide), oil on canvas, 54 x 65.7 cm, Museum of Fine Arts, Budapest.jpg")));
}

- (void)testNormalizedEquality {
    NSString *one = @"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ole.PNG/440px-Olé.PNG";
    NSString *two = @"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ole.PNG/440px-Ol\u00E9.PNG";
    NSString *three = @"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ole.PNG/440px-Ole\u0301.PNG";
    NSString *fn1 = WMFParseUnescapedNormalizedImageNameFromSourceURL(one);
    NSString *fn2 = WMFParseUnescapedNormalizedImageNameFromSourceURL(two);
    NSString *fn3 = WMFParseUnescapedNormalizedImageNameFromSourceURL(three);
    XCTAssertEqualObjects(fn1, fn2);
    XCTAssertEqualObjects(fn2, fn3);
}

- (void)testNormalizedEscapedEquality {

    NSString *one = [@"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ole.PNG/440px-Olé.PNG" stringByAddingPercentEncodingWithAllowedCharacters:[self allowedCharacters]];
    NSString *two = [@"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ole.PNG/440px-Ol\u00E9.PNG" stringByAddingPercentEncodingWithAllowedCharacters:[self allowedCharacters]];
    NSString *three = [@"https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Ole.PNG/440px-Ole\u0301.PNG" stringByAddingPercentEncodingWithAllowedCharacters:[self allowedCharacters]];
    NSString *fn1 = WMFParseUnescapedNormalizedImageNameFromSourceURL(one);
    NSString *fn2 = WMFParseUnescapedNormalizedImageNameFromSourceURL(two);
    NSString *fn3 = WMFParseUnescapedNormalizedImageNameFromSourceURL(three);
    XCTAssertEqualObjects(fn1, fn2);
    XCTAssertEqualObjects(fn2, fn3);
}

- (void)testImageWithMultiplePeriodsInFilename {
    NSString *testURLString =
        @"//upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg/440px-Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg")));
}

- (void)testPrefixFromNoPrefixFileName {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";

    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromImageWithOneExtensionExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 640);
}

- (void)testPrefixFromUrlWithoutImageFileLastPathComponent {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromZeroWidthImage {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/0px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromEmptyStringUrl {
    NSString *testURL = @"";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testPrefixFromNilUrl {
    NSString *testURL = nil;
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), NSNotFound);
}

- (void)testSizePrefixChangeOnNil {
    assertThat(WMFChangeImageSourceURLSizePrefix(nil, 123),
               is(equalTo(nil)));
}

- (void)testSizePrefixChangeOnEmptyString {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"", 123),
               is(equalTo(@"")));
}

- (void)testSizePrefixChangeOnSingleSlashString {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"/", 123),
               is(equalTo(@"/")));
}

- (void)testSizePrefixChangeOnSingleSpaceString {
    assertThat(WMFChangeImageSourceURLSizePrefix(@" ", 123),
               is(equalTo(@" ")));
}

- (void)testSizePrefixChangeOnSingleSlashSingleCharacterString {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"/a", 123),
               is(equalTo(@"/a")));
}

- (void)testSizePrefixChangeOnURLWithoutSizePrefix {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/a/a5/Buteo_magnirostris.jpg", 123),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Buteo_magnirostris.jpg/123px-Buteo_magnirostris.jpg")));
}

- (void)testSizePrefixChangeOnURLWithSizePrefix {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/200px-Potato.jpg/", 123),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/123px-Potato.jpg/")));
}

- (void)testSizePrefixChangeOnlyEffectsLastPathComponent {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/200px-/4/41/200px-Potato.jpg/", 123),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/200px-/4/41/123px-Potato.jpg/")));
}

- (void)testSizePrefixChange_jpeg {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/4/48/Oat10.jpeg", 123),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Oat10.jpeg/123px-Oat10.jpeg")));
}

- (void)testSizePrefixChange_JPEG {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/4/48/Oat10.JPEG", 123),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Oat10.JPEG/123px-Oat10.JPEG")));
}

- (void)testSizePrefixChangeOnENWikiURL {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/en/6/69/PercevalShooting.jpg", 123),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/en/thumb/6/69/PercevalShooting.jpg/123px-PercevalShooting.jpg")));
}

- (void)testSizePrefixChangeOnURLEndingWithWikipedia {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/", 123),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/")));
}

- (void)testSizePrefixChangeOnURLEndingWithWikipediaAndDoubleSlashes {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia//", 123),
               is(equalTo(@"//upload.wikimedia.org/wikipedia//")));
}

- (void)testParseImageNameFromURLofSVG {
    NSString *testURLString = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.svg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.svg.png";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.svg")));
}

- (void)testSizePrefixWhenCanonicalFileIsPDF {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 240);
}

- (void)testParseCanonicalFileNameWhenCanonicalFileIsPDF {
    NSString *testURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"A_Fish_and_a_Gift.pdf")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsPDFWithSizePrefix {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg", 480),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-480px-A_Fish_and_a_Gift.pdf.jpg")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsPDFWithSizePrefixPage2 {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page2-240px-A_Fish_and_a_Gift.pdf.jpg", 480),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page2-480px-A_Fish_and_a_Gift.pdf.jpg")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsPDFWithoutSizePrefix {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/6/65/A_Fish_and_a_Gift.pdf", 240),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg")));
}

- (void)testSizePrefixChangeOnCanonicalImageURLWithSizePrefixInFileName {
    // Normally images only have "XXXpx-" size prefix when returned from the thumbnail scaler, but there's nothing stopping users from uploading images with "XXXpx-" size prefix in the canonical name.
    // (See last image on "enwiki > Geothermal gradient")
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png", 100),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/300px-Geothermgradients.png/100px-300px-Geothermgradients.png")));
}

- (void)testResizePrefixChangeOnCanonicalImageURLWithSizePrefixInFileName {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/300px-Geothermgradients.png/100px-300px-Geothermgradients.png", 200),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/300px-Geothermgradients.png/200px-300px-Geothermgradients.png")));
}

- (void)testParseImageNameFromCanonicalImageURLWithSizePrefixInFileName {
    NSString *testURLString = @"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"300px-Geothermgradients.png")));
    //                      ^ the canonical image has the size in the file name, so "300px-" is correct here.
}

- (void)testSizePrefixWhenCanonicalFileIsTIF_lossy {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 220);
}

- (void)testParseCanonicalFileNameWhenCanonicalFileIsTIF_lossy {
    NSString *testURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"Gerald_Ford_-_NARA_-_530680.tif")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefix_lossy {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg", 480),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-480px-Gerald_Ford_-_NARA_-_530680.tif.jpg")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefixPage2_lossy {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page2-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg", 480),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page2-480px-Gerald_Ford_-_NARA_-_530680.tif.jpg"))); //Note: this page2 variant doesn't actually exist.
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithoutSizePrefix_lossy {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/d/d0/Gerald_Ford_-_NARA_-_530680.tif", 240),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-240px-Gerald_Ford_-_NARA_-_530680.tif.jpg")));
}

- (void)testSizePrefixWhenCanonicalFileIsTIF_lossless {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.png";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 220);
}

- (void)testParseCanonicalFileNameWhenCanonicalFileIsTIF_lossless {
    NSString *testURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.png";
    assertThat(WMFParseImageNameFromSourceURL(testURLString),
               is(equalTo(@"Gerald_Ford_-_NARA_-_530680.tif")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefix_lossless {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.png", 480),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-480px-Gerald_Ford_-_NARA_-_530680.tif.png")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefixPage2_lossless {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page2-220px-Gerald_Ford_-_NARA_-_530680.tif.png", 480),
               is(equalTo(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page2-480px-Gerald_Ford_-_NARA_-_530680.tif.png"))); //Note: this page2 variant doesn't actually exist.
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFF_lowercase {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/f/f8/Funk.tiff", 797),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Funk.tiff/lossy-page1-797px-Funk.tiff.jpg")));
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFF_uppercase {
    assertThat(WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/5/55/Charles_Vanderhoop%2C_Jr.%2C_Gay_Head_Light_Assistant_Keeper%2C_with_visiting_island_school_children.TIFF", 800),
               is(equalTo(@"https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Charles_Vanderhoop%2C_Jr.%2C_Gay_Head_Light_Assistant_Keeper%2C_with_visiting_island_school_children.TIFF/lossy-page1-800px-Charles_Vanderhoop%2C_Jr.%2C_Gay_Head_Light_Assistant_Keeper%2C_with_visiting_island_school_children.TIFF.jpg")));
}

@end
