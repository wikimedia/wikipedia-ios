//
//  UIImageView+WMFImageFetchingVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import XCTest;
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+PromiseKit.h"
#import "WMFImageController+Testing.h"
#import "Wikipedia-Swift.h"
#import <Nocilla/Nocilla.h>

#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFFaceDetectionCache.h"

@interface UIImageViewWMFImageFetchingVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) UIImageView* imageView;

@end

@implementation UIImageViewWMFImageFetchingVisualTests

- (void)setUp {
    [super setUp];

    self.recordMode     = [[NSUserDefaults standardUserDefaults] wmf_visualTestBatchRecordMode];
    self.deviceAgnostic = YES;

    [[LSNocilla sharedInstance] start];
    self.imageView                     = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 160)];
    self.imageView.contentMode         = UIViewContentModeScaleAspectFill;
    self.imageView.wmf_imageController = [WMFImageController temporaryController];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [[UIImageView faceDetectionCache] clearCache];
    [self.imageView.wmf_imageController deleteAllImages];
    [super tearDown];
}

- (void)testCentersPresObamasFaceVertically {
    [self verifyCenteringOfFacesInFixtureNamed:@"640px-President_Barack_Obama.jpg"];
}

- (void)testCentersBothActorsFacesVertically {
    [self verifyCenteringOfFacesInFixtureNamed:@"Spider-Man_actors.jpg"];
}

- (void)testUsesSpecifiedContentModeBehaviorOnFeaturelessImage {
    [self verifyCenteringOfFacesInFixtureNamed:@"golden-gate.jpg"];
}

#pragma mark - Utils

- (void)verifyCenteringOfFacesInFixtureNamed:(NSString*)imageFixtureName {
    // !!!: Need to use different URLs to prevent reusing face detection data for different images
    NSURL* testURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://test/%@.jpg", imageFixtureName]];

    UIImage* testImage =
        [UIImage imageNamed:imageFixtureName inBundle:[self wmf_bundle] compatibleWithTraitCollection:nil];

    NSAssert(testImage,
             @"Couldn't find image fixture named %@. Make sure it's included in the unit testing target.",
             imageFixtureName);

    stubRequest(@"GET", testURL.absoluteString)
    .andReturn(200)
    .withBody(UIImageJPEGRepresentation(testImage, 1.f));

    expectResolutionWithTimeout(10, ^{
        return [self.imageView wmf_setImageWithURL:testURL detectFaces:YES].then(^{
            WMFSnapshotVerifyView(self.imageView);
        });
    });
}

@end
