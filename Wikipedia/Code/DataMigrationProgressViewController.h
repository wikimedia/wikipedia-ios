
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class DataMigrationProgressViewController;

typedef void (^ WMFDataMigrationCompletionBlock)(BOOL migrationCompleted);

@interface DataMigrationProgressViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIProgressView* progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel* progressLabel;

- (BOOL)needsMigration;

- (void)runMigrationWithCompletion:(WMFDataMigrationCompletionBlock)completion;

- (void)removeOldDataBackupIfNeeded;


@end
