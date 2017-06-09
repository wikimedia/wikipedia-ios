#import <XCTest/XCTest.h>

#import "MWKArticleStoreTestCase.h"

@interface MWKImageStorageTests : MWKArticleStoreTestCase

@property NSString *goldenGateImageURL;

@end

@implementation MWKImageStorageTests

- (void)setUp {
    [super setUp];
    self.goldenGateImageURL = @"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Golden_Gate_Bridge%2C_SF_%28cropped%29.jpg/500px-Golden_Gate_Bridge%2C_SF_%28cropped%29.jpg";
    [self.article importMobileViewJSON:self.json0[@"mobileview"]];
    [self.article importMobileViewJSON:self.json1[@"mobileview"]];
}

- (void)testLoadNonexistentImage {
    // This should hand us a new image object
    XCTAssertNotNil([[MWKImage alloc] initWithArticle:self.article sourceURLString:self.goldenGateImageURL]);
}

- (void)testLoadNonexistentImageData {
    MWKImage *image = [[MWKImage alloc] initWithArticle:self.article sourceURLString:self.goldenGateImageURL];
    XCTAssertNotNil(image);
}

@end
