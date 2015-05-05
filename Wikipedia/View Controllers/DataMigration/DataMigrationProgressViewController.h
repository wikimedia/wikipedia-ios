
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class DataMigrationProgressViewController;
@class WMFProgressLineView;

@protocol DataMigrationProgressDelegate
- (void)dataMigrationProgressComplete:(DataMigrationProgressViewController*)viewController;
@end


@interface DataMigrationProgressViewController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet WMFProgressLineView* progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel* progressLabel;
@property (weak, nonatomic) id<DataMigrationProgressDelegate> delegate;

- (BOOL)needsMigration;


- (void)moveOldDataToBackupLocation;


- (void)removeOldDataBackupIfNeeded;


@end
