#import "MWKArticleStoreTestCase.h"

@interface MWKImageVarianceTests : MWKArticleStoreTestCase

@end

@implementation MWKImageVarianceTests

- (void)setUp {
    [super setUp];
}

- (void)testTwoActualVariants {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/40px-Example.jpg"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testTwoNonVariantsBecauseFileNamesDiffer {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Goat.jpg/20px-Goat.jpg"];

    XCTAssertFalse([image1 isVariantOfImage:image2]);
}

- (void)testTwoNonVariantsBecauseTheirPathsDifferEvenThoughFileNameIsSame {
    // On "enwiki > Kleiner Hefner > History" peek 3rd and 4th images was showing 2nd image instead.
    // The reason was "isVariantOfImage" thought they were variants because it was only taking file
    // name instead of path into account. The urls below are from the 2nd and 3rd image on that page.
    // (It looks like the thumbnailer doesn't prefix the file name with "XXXpx-" if the file name is
    // very long, as it is the urls below.)

    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.wikimedia.org/wikipedia/commons/thumb/9/95/Arch%C3%A4ologie_im_Parkhaus_Op%C3%A9ra_-_Ausstellung_im_Tiefparkhaus_Sechsel%C3%A4utenplatz_-_Horgener_Kultur_-_Fragment_eines_Topfes_mit_%28%21%29_Verzierungen_2014-10-31_17-09-36.jpg/120px-thumbnail.jpg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Arch%C3%A4ologie_im_Parkhaus_Op%C3%A9ra_-_Ausstellung_im_Tiefparkhaus_Sechsel%C3%A4utenplatz_-_Horgener_Kultur_-_Steinbeil_in_%27Zwischenfutter%27_aus_Hirschgeweih_aus_Originalsediment_2014-10-31_17-10-11.jpg/120px-thumbnail.jpg"];

    XCTAssertFalse([image1 isVariantOfImage:image2]);
}

- (void)testTwoActualVariantsHavingDifferentSchemes {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"https://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/40px-Example.jpg"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testTwoActualVariantsWithOneHavingSchemeAndOneNotHavingScheme {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/40px-Example.jpg"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testTwoActualVariantsIfEqualURLs {
    NSString *urlString = @"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpg/20px-Example.jpg";

    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:urlString];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:urlString];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testPNGs {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.png/20px-Thumbnail.png"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.png/40px-Example.png"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testGIFs {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.gif/20px-Example.gif"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.gif/40px-Example.gif"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testJPEGs {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpeg/20px-Example.jpeg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.jpeg/40px-Example.jpeg"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testTIFFs {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.tiff/20px-Example.tiff"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.tiff/40px-Example.tiff"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

- (void)testXCFs {
    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"http://upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.xcf/20px-Example.xcf"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.beta.wmflabs.org/wikipedia/commons/thumb/a/a9/Example.xcf/40px-Example.xcf"];

    XCTAssertTrue([image1 isVariantOfImage:image2]);
}

@end
