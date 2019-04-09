@import XCTest;
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "FBSnapshotTestCase+WMFConvenience.h"
#import "Wikipedia-Swift.h"
#import "WMFAsyncTestCase.h"
#import <Nocilla/Nocilla.h>

#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFFaceDetectionCache.h"

@interface UIImageViewWMFImageFetchingVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation UIImageViewWMFImageFetchingVisualTests

- (void)setUp {
    [super setUp];

    self.recordMode = WMFIsVisualTestRecordModeEnabled;

    [[LSNocilla sharedInstance] start];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 160)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.wmf_imageController = [WMFImageController temporaryController];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [[UIImageView faceDetectionCache] clearCache];
    [self.imageView.wmf_imageController deleteTemporaryCache];
    [super tearDown];
}

- (void)testCentersPresObamasFaceVertically {
    [self verifyCenteringOfFacesInFixtureNamed:@"640px-President_Barack_Obama.jpg"];
}

- (void)testImageNotCroppedBecauseFacesAreTooSmall {
    [self verifyCenteringOfFacesInFixtureNamed:@"Spider-Man_actors.jpg"];
}

- (void)testUsesSpecifiedContentModeBehaviorOnFeaturelessImage {
    [self verifyCenteringOfFacesInFixtureNamed:@"golden-gate.jpg"];
}

- (void)testImageShorterThanViewIsNotStretched {
    [self verifyCenteringOfFacesInFixtureNamed:@"640px-Shoso-in.jpg"];
}

#pragma mark - Utils

- (void)verifyCenteringOfFacesInFixtureNamed:(NSString *)imageFixtureName {
    // !!!: Need to use different URLs to prevent reusing face detection data for different images
    NSURL *testURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://test/%@.jpg", imageFixtureName]];

    UIImage *testImage = [UIImage imageWithData:[[self wmf_bundle] wmf_dataFromContentsOfFile:imageFixtureName ofType:nil]];

    NSAssert(testImage,
             @"Couldn't find image fixture named %@. Make sure it's included in the unit testing target.",
             imageFixtureName);

    stubRequest(@"GET", testURL.absoluteString)
        .andReturn(200)
        .withBody(UIImageJPEGRepresentation(testImage, 1.f));

    XCTestExpectation *expectation = [self expectationWithDescription:@"waiting for image set"];

    [self.imageView wmf_setImageWithURL:testURL
        detectFaces:YES
        failure:^(NSError *error) {
            XCTFail();
            [expectation fulfill];
        }
        success:^{
            WMFSnapshotVerifyViewForOSAndWritingDirection(self.imageView);
            [expectation fulfill];
        }];

    WaitForExpectationsWithTimeout(10);
}

@end
