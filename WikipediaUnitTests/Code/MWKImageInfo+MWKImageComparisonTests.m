#import "MWKImageInfo+MWKImageComparison.h"
#import <XCTest/XCTest.h>
#import "MWKImage+AssociationTestUtils.h"

@interface MWKImageInfo_MWKImageComparisonTests : XCTestCase

@end

@implementation MWKImageInfo_MWKImageComparisonTests

- (void)testAssociation {
    MWKImage *image = [MWKImage imageAssociatedWithSourceURL:@"/thumb/some_file_name.jpg/400px-some_file_name.jpg"];
    MWKImageInfo *info = [MWKImageInfo infoAssociatedWithSourceURL:@"/thumb/some_file_name.jpg/800px-some_file_name.jpg"];
    XCTAssert([image.infoAssociationValue isEqual:info.imageAssociationValue]);
    XCTAssert([info isAssociatedWithImage:image]);
    XCTAssert([image isAssociatedWithInfo:info]);
}

- (void)testDisassociation {
    MWKImage *image = [MWKImage imageAssociatedWithSourceURL:@"/thumb/some_file_name.jpg/400px-some_file_name.jpg"];
    MWKImageInfo *info = [MWKImageInfo infoAssociatedWithSourceURL:@"/thumb/other_file_name.jpg/800px-other_file_name.jpg"];
    XCTAssert(![[image infoAssociationValue] isEqual:[info imageAssociationValue]]);
    XCTAssertFalse([info isAssociatedWithImage:image]);
}

@end
