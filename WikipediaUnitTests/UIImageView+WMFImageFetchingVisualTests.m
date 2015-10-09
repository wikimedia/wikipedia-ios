//
//  UIImageView+WMFImageFetchingVisualTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/9/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "FBSnapshotTestCase+WMFConvenience.h"
#import "XCTestCase+PromiseKit.h"
#import "WMFImageController+Testing.h"
#import "WMFAsyncTestCase.h"
#import "WMFTestFixtureUtilities.h"

#import "UIImageView+WMFImageFetchingInternal.h"
#import "WMFFaceDetectionCache.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>
#import <Nocilla/Nocilla.h>

@interface UIImageViewWMFImageFetchingVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) UIImageView* imageView;

@end

@implementation UIImageViewWMFImageFetchingVisualTests

- (void)setUp {
    [super setUp];

    self.recordMode = YES;

    [[LSNocilla sharedInstance] start];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 160)];
    self.imageView.wmf_imageController = [WMFImageController temporaryController];
    [[UIImageView faceDetectionCache] clearCache];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [self.imageView.wmf_imageController deleteAllImages];
    [super tearDown];
}

- (void)testCentersPresObamasFaceVertically {
    [self verifyCenteringOfFacesInFixtureNamed:@"640px-President_Barack_Obama.jpg"];
}

- (void)testCentersBothActorsFacesVertically {
    [self verifyCenteringOfFacesInFixtureNamed:@"Spider-Man_actors.jpg"];
}

#pragma mark - Utils

- (void)verifyCenteringOfFacesInFixtureNamed:(NSString*)imageFixtureName {
    // !!!: Need to use different URLs to prevent reusing face detection data for different images
    NSURL* testURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://test/%@.jpg", imageFixtureName]];

    UIImage* imageWithFaces = [UIImage imageNamed:imageFixtureName
                                         inBundle:[self wmf_bundle]
                    compatibleWithTraitCollection:nil];

    NSAssert(imageWithFaces,
             @"Couldn't find image fixture named %@. Make sure it's included in the unit testing target.",
             imageFixtureName);

    stubRequest(@"GET", testURL.absoluteString)
    .andReturn(200)
    .withBody(UIImageJPEGRepresentation(imageWithFaces, 1.f));

    [self expectAnyPromiseToResolve:^AnyPromise*{
        return [self.imageView wmf_setImageWithURL:testURL detectFaces:YES];
    } timeout:2 WMFExpectFromHere];

    WMFSnapshotVerifyView(self.imageView);
}

@end
