#import "FBSnapshotTestCase+WMFConvenience.h"
#import "WMFSettingsTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "UIView+VisualTestSizingUtils.h"

@interface WMFSettingsCellVisualTests : FBSnapshotTestCase
@property (nonatomic, strong) WMFSettingsTableViewCell *cell;
@end

@implementation WMFSettingsCellVisualTests

- (void)setUp {
    [super setUp];
    self.recordMode = WMFIsVisualTestRecordModeEnabled;
    self.cell = [WMFSettingsTableViewCell wmf_viewFromClassNib];
    [self configureCell:self.cell];
}

- (void)configureCell:(WMFSettingsTableViewCell *)cell {
    self.cell.iconName = @"settings-faq";
    self.cell.iconColor = [UIColor grayColor];
    self.cell.disclosureType = WMFSettingsMenuItemDisclosureType_Switch;
}

- (void)verifyCell:(WMFSettingsTableViewCell *)cell withTitle:(NSString *)title {
    self.cell.title = title;
    [self.cell wmf_sizeToFitWidth:320];
    WMFSnapshotVerifyViewForOSAndWritingDirection(self.cell);
}

- (void)tearDown {
    [super tearDown];
}

- (void)testShortTitle {
    [self verifyCell:self.cell withTitle:@"Should be one line."];
}

- (void)testLongTitle {
    [self verifyCell:self.cell withTitle:@"This should be at least five or six lines of text so we can obviously see that the cell height grows to encompass long translations even though they'll probably never be this long."];
}

@end
