@import WMF;

#import "FBSnapshotTestCase+WMFConvenience.h"

@interface WMFArticlePreviewViewController (WMFArticleViewControllerVisualTesting)
@end

@implementation WMFArticlePreviewViewController (WMFArticleViewControllerVisualTesting)

- (void)wmf_configureForVisualTestingByOnlyShowingBordersForCertainViews {
    self.titleHTML = @" ";
    for (UIView *view in @[self.imageView, self.titleLabel, self.rankLabel, self.subtitleLabel, self.viewCountAndSparklineContainerView]) {
        view.layer.borderWidth = 1;
        view.backgroundColor = [UIColor clearColor];
        if ([view respondsToSelector:@selector(setTextColor:)]) {
            [view performSelector:@selector(setTextColor:) withObject:[UIColor clearColor]];
        }
        for (UIView *subView in view.subviews) {
            subView.alpha = 0;
            subView.backgroundColor = [UIColor clearColor];
        }
    }
}

@end

@interface WMFArticlePreviewViewControllerVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFArticlePreviewViewController *controller;
@end

@implementation WMFArticlePreviewViewControllerVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = WMFIsVisualTestRecordModeEnabled;
    self.controller = [[WMFArticlePreviewViewController alloc] init];
    [self.controller.view setHidden:NO];
    [self.controller wmf_configureForVisualTestingByOnlyShowingBordersForCertainViews];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testWithImage {
    self.controller.collapseImageAndWidenLabels = NO;
    [self wmf_verifyView:self.controller.view];
}

- (void)testWithoutImage {
    self.controller.collapseImageAndWidenLabels = YES;
    [self wmf_verifyView:self.controller.view];
}

- (void)testWithImageAndNoSubtitle {
    self.controller.collapseImageAndWidenLabels = NO;
    self.controller.subtitleLabel.text = nil;
    [self wmf_verifyView:self.controller.view];
}

- (void)testWithoutImageAndNoSubtitle {
    self.controller.collapseImageAndWidenLabels = YES;
    self.controller.subtitleLabel.text = nil;
    [self wmf_verifyView:self.controller.view];
}

@end
