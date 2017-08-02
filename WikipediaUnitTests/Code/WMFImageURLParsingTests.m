#import <XCTest/XCTest.h>
#import "WMFImageURLParsing.h"

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
    XCTAssert([WMFParseImageNameFromSourceURL(testURL) isEqualToString:@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg"]);
}

- (void)testImageWithOneExtensionExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg";
    XCTAssert([WMFParseImageNameFromSourceURL(testURL) isEqualToString:@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.jpg"]);
}

- (void)testImageWithTwoExtensionsExample {
    NSString *testURL = @"http://upload.wikimedia.org/wikipedia/commons/thumb/3/34/Access_to_drinking_water_in_third_world.svg/320px-Access_to_drinking_water_in_third_world.svg.png";
    XCTAssert([WMFParseImageNameFromSourceURL(testURL) isEqualToString:@"Access_to_drinking_water_in_third_world.svg"]);
}

- (void)testImageWithPeriodInFileNameExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg";
    XCTAssert([WMFParseImageNameFromSourceURL(testURL) isEqualToString:@"Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg"]);
}

- (void)testNormalizedImageWithPeriodInFileNameExample {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg";
    NSString *normalized = WMFParseUnescapedNormalizedImageNameFromSourceURL(testURL);
    XCTAssert([normalized isEqualToString:@"Claude Monet, 1870, Le port de Trouville (Breakwater at Trouville, Low Tide), oil on canvas, 54 x 65.7 cm, Museum of Fine Arts, Budapest.jpg"]);
}

- (void)testNormalizedImageWithPeriodInFileNameFromURLExample {
    NSURL *testURL = [NSURL URLWithString:@"//upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg/360px-Claude_Monet%2C_1870%2C_Le_port_de_Trouville_%28Breakwater_at_Trouville%2C_Low_Tide%29%2C_oil_on_canvas%2C_54_x_65.7_cm%2C_Museum_of_Fine_Arts%2C_Budapest.jpg"];
    NSString *normalized = WMFParseUnescapedNormalizedImageNameFromSourceURL(testURL);
    XCTAssert([normalized isEqualToString:@"Claude Monet, 1870, Le port de Trouville (Breakwater at Trouville, Low Tide), oil on canvas, 54 x 65.7 cm, Museum of Fine Arts, Budapest.jpg"]);
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
    XCTAssert([WMFParseImageNameFromSourceURL(testURLString) isEqualToString:@"Blacksmith%27s_tools_-_geograph.org.uk_-_1483374.jpg"]);
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
    XCTAssert(WMFChangeImageSourceURLSizePrefix(nil, 123) == nil);
}

- (void)testSizePrefixChangeOnEmptyString {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"", 123) isEqualToString:@""]);
}

- (void)testSizePrefixChangeOnSingleSlashString {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"/", 123) isEqualToString:@"/"]);
}

- (void)testSizePrefixChangeOnSingleSpaceString {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@" ", 123) isEqualToString:@" "]);
}

- (void)testSizePrefixChangeOnSingleSlashSingleCharacterString {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"/a", 123) isEqualToString:@"/a"]);
}

- (void)testSizePrefixChangeOnURLWithoutSizePrefix {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/a/a5/Buteo_magnirostris.jpg", 123) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Buteo_magnirostris.jpg/123px-Buteo_magnirostris.jpg"]);
}

- (void)testSizePrefixChangeOnURLWithSizePrefix {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/200px-Potato.jpg/", 123) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/123px-Potato.jpg/"]);
}

- (void)testSizePrefixChangeOnlyEffectsLastPathComponent {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/200px-/4/41/200px-Potato.jpg/", 123) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/200px-/4/41/123px-Potato.jpg/"]);
}

- (void)testSizePrefixChange_jpeg {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/4/48/Oat10.jpeg", 123) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Oat10.jpeg/123px-Oat10.jpeg"]);
}

- (void)testSizePrefixChange_JPEG {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/4/48/Oat10.JPEG", 123) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Oat10.JPEG/123px-Oat10.JPEG"]);
}

- (void)testSizePrefixChangeOnENWikiURL {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/en/6/69/PercevalShooting.jpg", 123) isEqualToString:@"//upload.wikimedia.org/wikipedia/en/thumb/6/69/PercevalShooting.jpg/123px-PercevalShooting.jpg"]);
}

- (void)testSizePrefixChangeOnURLEndingWithWikipedia {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/", 123) isEqualToString:@"//upload.wikimedia.org/wikipedia/"]);
}

- (void)testSizePrefixChangeOnURLEndingWithWikipediaAndDoubleSlashes {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia//", 123) isEqualToString:@"//upload.wikimedia.org/wikipedia//"]);
}

- (void)testParseImageNameFromURLofSVG {
    NSString *testURLString = @"//upload.wikimedia.org/wikipedia/commons/thumb/4/41/Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.svg/640px-Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.svg.png";
    XCTAssert([WMFParseImageNameFromSourceURL(testURLString) isEqualToString:@"Iceberg_with_hole_near_Sandersons_Hope_2007-07-28_2.svg"]);
}

- (void)testSizePrefixWhenCanonicalFileIsPDF {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 240);
}

- (void)testParseCanonicalFileNameWhenCanonicalFileIsPDF {
    NSString *testURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg";
    XCTAssert([WMFParseImageNameFromSourceURL(testURLString) isEqualToString:@"A_Fish_and_a_Gift.pdf"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsPDFWithSizePrefix {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg", 480) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-480px-A_Fish_and_a_Gift.pdf.jpg"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsPDFWithSizePrefixPage2 {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page2-240px-A_Fish_and_a_Gift.pdf.jpg", 480) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page2-480px-A_Fish_and_a_Gift.pdf.jpg"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsPDFWithoutSizePrefix {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/6/65/A_Fish_and_a_Gift.pdf", 240) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg"]);
}

- (void)testSizePrefixChangeOnCanonicalImageURLWithSizePrefixInFileName {
    // Normally images only have "XXXpx-" size prefix when returned from the thumbnail scaler, but there's nothing stopping users from uploading images with "XXXpx-" size prefix in the canonical name.
    // (See last image on "enwiki > Geothermal gradient")
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png", 100) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/300px-Geothermgradients.png/100px-300px-Geothermgradients.png"]);
}

- (void)testResizePrefixChangeOnCanonicalImageURLWithSizePrefixInFileName {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/300px-Geothermgradients.png/100px-300px-Geothermgradients.png", 200) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/0/0b/300px-Geothermgradients.png/200px-300px-Geothermgradients.png"]);
}

- (void)testParseImageNameFromCanonicalImageURLWithSizePrefixInFileName {
    NSString *testURLString = @"//upload.wikimedia.org/wikipedia/commons/0/0b/300px-Geothermgradients.png";
    XCTAssert([WMFParseImageNameFromSourceURL(testURLString) isEqualToString:@"300px-Geothermgradients.png"]);
    //                      ^ the canonical image has the size in the file name, so "300px-" is correct here.
}

- (void)testSizePrefixWhenCanonicalFileIsTIF_lossy {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 220);
}

- (void)testParseCanonicalFileNameWhenCanonicalFileIsTIF_lossy {
    NSString *testURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg";
    XCTAssert([WMFParseImageNameFromSourceURL(testURLString) isEqualToString:@"Gerald_Ford_-_NARA_-_530680.tif"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefix_lossy {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg", 480) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-480px-Gerald_Ford_-_NARA_-_530680.tif.jpg"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefixPage2_lossy {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page2-220px-Gerald_Ford_-_NARA_-_530680.tif.jpg", 480) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page2-480px-Gerald_Ford_-_NARA_-_530680.tif.jpg"]); //Note: this page2 variant doesn't actually exist.
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithoutSizePrefix_lossy {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/d/d0/Gerald_Ford_-_NARA_-_530680.tif", 240) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossy-page1-240px-Gerald_Ford_-_NARA_-_530680.tif.jpg"]);
}

- (void)testSizePrefixWhenCanonicalFileIsTIF_lossless {
    NSString *testURL = @"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.png";
    XCTAssertEqual(WMFParseSizePrefixFromSourceURL(testURL), 220);
}

- (void)testParseCanonicalFileNameWhenCanonicalFileIsTIF_lossless {
    NSString *testURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.png";
    XCTAssert([WMFParseImageNameFromSourceURL(testURLString) isEqualToString:@"Gerald_Ford_-_NARA_-_530680.tif"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefix_lossless {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-220px-Gerald_Ford_-_NARA_-_530680.tif.png", 480) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page1-480px-Gerald_Ford_-_NARA_-_530680.tif.png"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFWithSizePrefixPage2_lossless {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page2-220px-Gerald_Ford_-_NARA_-_530680.tif.png", 480) isEqualToString:@"//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Gerald_Ford_-_NARA_-_530680.tif/lossless-page2-480px-Gerald_Ford_-_NARA_-_530680.tif.png"]); //Note: this page2 variant doesn't actually exist.
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFF_lowercase {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/f/f8/Funk.tiff", 797) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Funk.tiff/lossy-page1-797px-Funk.tiff.jpg"]);
}

- (void)testSizePrefixChangeWhenCanonicalFileIsTIFF_uppercase {
    XCTAssert([WMFChangeImageSourceURLSizePrefix(@"https://upload.wikimedia.org/wikipedia/commons/5/55/Charles_Vanderhoop%2C_Jr.%2C_Gay_Head_Light_Assistant_Keeper%2C_with_visiting_island_school_children.TIFF", 800) isEqualToString:@"https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Charles_Vanderhoop%2C_Jr.%2C_Gay_Head_Light_Assistant_Keeper%2C_with_visiting_island_school_children.TIFF/lossy-page1-800px-Charles_Vanderhoop%2C_Jr.%2C_Gay_Head_Light_Assistant_Keeper%2C_with_visiting_island_school_children.TIFF.jpg"]);
}

@end
