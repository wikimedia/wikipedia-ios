
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class DataMigrationProgressViewController;
@class WMFProgressLineView;

typedef void (^ WMFDataMigrationCompletionBlock)(BOOL migrationCompleted);

@interface DataMigrationProgressViewController : UIViewController

@property (weak, nonatomic) IBOutlet WMFProgressLineView* progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel* progressLabel;

- (BOOL)needsMigration;

- (void)runMigrationWithCompletion:(WMFDataMigrationCompletionBlock)completion;

- (void)removeOldDataBackupIfNeeded;


@end
