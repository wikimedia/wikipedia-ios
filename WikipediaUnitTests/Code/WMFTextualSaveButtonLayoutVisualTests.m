#import "FBSnapshotTestCase+WMFConvenience.h"
#import "UIView+VisualTestSizingUtils.h"
#import "WMFLeadingImageTrailingTextButton.h"

@interface WMFTextualSaveButtonLayoutVisualTests : FBSnapshotTestCase

@property (nonatomic, strong) WMFLeadingImageTrailingTextButton *saveButton;

@end

@implementation WMFTextualSaveButtonLayoutVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = [[NSUserDefaults standardUserDefaults] wmf_visualTestBatchRecordMode];
    // these tests don't care about device (or window size), only OS version & writing direction
    self.deviceAgnostic = NO;
    // record snapshots at fixed size (regardless of window size) which must be larger than the content itself
    // in order to verify alignment with leading edge in LTR & RTL
    self.saveButton = [[WMFLeadingImageTrailingTextButton alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    [self.saveButton configureAsSaveButton];
}

- (void)testLaysOutProperly {
    WMFSnapshotVerifyViewForOSAndWritingDirection(self.saveButton);
}

@end
