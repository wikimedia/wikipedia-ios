#import "MWKImageInfo+MWKImageComparison.h"
#import <XCTest/XCTest.h>

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "MWKImage+AssociationTestUtils.h"

@interface MWKImageInfo_MWKImageComparisonTests : XCTestCase

@end

@implementation MWKImageInfo_MWKImageComparisonTests

- (void)testAssociation {
    MWKImage* image    = [MWKImage imageAssociatedWithSourceURL:@"/thumb/some_file_name.jpg/400px-some_file_name.jpg"];
    MWKImageInfo* info = [MWKImageInfo infoAssociatedWithSourceURL:@"/thumb/some_file_name.jpg/800px-some_file_name.jpg"];
    assertThat(image.infoAssociationValue, is(equalTo(info.imageAssociationValue)));
    XCTAssertTrue([info isAssociatedWithImage:image]);
    XCTAssertTrue([image isAssociatedWithInfo:info]);
}

- (void)testDisassociation {
    MWKImage* image    = [MWKImage imageAssociatedWithSourceURL:@"/thumb/some_file_name.jpg/400px-some_file_name.jpg"];
    MWKImageInfo* info = [MWKImageInfo infoAssociatedWithSourceURL:@"/thumb/other_file_name.jpg/800px-other_file_name.jpg"];
    assertThat([image infoAssociationValue], isNot(equalTo([info imageAssociationValue])));
    XCTAssertFalse([info isAssociatedWithImage:image]);
}

@end
