#import "MWKArticleStoreTestCase.h"

@interface MWKImageEqualityTests : MWKArticleStoreTestCase

@end

@implementation MWKImageEqualityTests

- (void)setUp {
    [super setUp];
}

- (void)testIsEqualToImageDoesNotConsiderTwoImagesWithSameFileNameButDifferentPathsToBeEqual {
    /*
     If the image file name is extremely long, it looks like the image scaler will shorten the scaled image name to "XXXpx-thumbnail.jpg" - so we can't necessarily use just the file name for equality check.
     
     See the 2nd, 3rd and 4th images on "enwiki > Kleiner Hefner > History" - they all have file name of "640px-thumbnail.jpg", but they are different images. Peeking on 3rd or 4th images was causing 2nd image to peek, and this was because previously isEqualToImage only compared the file name, ie "640px-thumbnail.jpg", instead of the full url.
     */

    MWKImage *image1 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.wikimedia.org/wikipedia/commons/thumb/9/95/Arch%C3%A4ologie_im_Parkhaus_Op%C3%A9ra_-_Ausstellung_im_Tiefparkhaus_Sechsel%C3%A4utenplatz_-_Horgener_Kultur_-_Fragment_eines_Topfes_mit_%28%21%29_Verzierungen_2014-10-31_17-09-36.jpg/640px-thumbnail.jpg"];

    MWKImage *image2 = [[MWKImage alloc] initWithArticle:self.article sourceURLString:@"//upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Arch%C3%A4ologie_im_Parkhaus_Op%C3%A9ra_-_Ausstellung_im_Tiefparkhaus_Sechsel%C3%A4utenplatz_-_Horgener_Kultur_-_Steinbeil_in_%27Zwischenfutter%27_aus_Hirschgeweih_aus_Originalsediment_2014-10-31_17-10-11.jpg/640px-thumbnail.jpg"];

    XCTAssertFalse([image1 isEqualToImage:image2]);
}

@end
