@import WMFUI;

#import <UIKit/UIKit.h>
#import "FBSnapshotTestCase+WMFConvenience.h"

@interface WMFArticleViewController (WMFArticleViewControllerVisualTesting)
@end

@implementation WMFArticleViewController (WMFArticleViewControllerVisualTesting)

- (void)wmf_configureForVisualTestingByOnlyShowingBordersForCertainViews {
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

@interface WMFArticleViewControllerVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFArticleViewController *controller;
@end

@implementation WMFArticleViewControllerVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = [[NSUserDefaults wmf_userDefaults] wmf_visualTestBatchRecordMode];
    self.deviceAgnostic = YES;
    self.controller = [[WMFArticleViewController alloc] init];
    [self.controller.view setHidden:NO];
    [self.controller wmf_configureForVisualTestingByOnlyShowingBordersForCertainViews];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testWithImage {
    self.controller.collapseImageAndWidenLabels = NO;
    [self wmf_verifyViewAtWindowWidth:self.controller.view];
}

- (void)testWithoutImage {
    self.controller.collapseImageAndWidenLabels = YES;
    [self wmf_verifyViewAtWindowWidth:self.controller.view];
}

- (void)testWithImageAndNoSubtitle {
    self.controller.collapseImageAndWidenLabels = NO;
    self.controller.subtitleLabel.text = nil;
    [self wmf_verifyViewAtWindowWidth:self.controller.view];
}

- (void)testWithoutImageAndNoSubtitle {
    self.controller.collapseImageAndWidenLabels = YES;
    self.controller.subtitleLabel.text = nil;
    [self wmf_verifyViewAtWindowWidth:self.controller.view];
}

@end
