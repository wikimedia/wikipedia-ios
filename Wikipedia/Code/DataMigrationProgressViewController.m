
#import "DataMigrationProgressViewController.h"
#import "MWKUserDataStore.h"
#import "SessionSingleton.h"

#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"

#import <BlocksKit/BlocksKit+UIKit.h>

typedef NS_ENUM (NSInteger, MigrationButtonIndexIds) {
    BUTTON_INDEX_DISCARD = 0,
    BUTTON_INDEX_SUBMIT  = 1
};

@interface DataMigrationProgressViewController ()< MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) WMFDataMigrationCompletionBlock completionBlock;

@end

@implementation DataMigrationProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.progressLabel.text = MWLocalizedString(@"migration-update-progress-label", nil);
}

- (void)runMigrationWithCompletion:(WMFDataMigrationCompletionBlock)completion {
    self.completionBlock = completion;

    UIAlertView* dialog = [UIAlertView bk_alertViewWithTitle:MWLocalizedString(@"migration-prompt-title", nil) message:MWLocalizedString(@"migration-prompt-message", nil)];

    [dialog bk_setCancelButtonWithTitle:MWLocalizedString(@"migration-skip-button-title", nil) handler:^{
        [self dispatchCOmpletionBlockWithStatus:NO];
    }];
    [dialog bk_addButtonWithTitle:MWLocalizedString(@"migration-confirm-button-title", nil) handler:^{
        [self performMigration];
    }];

    [dialog show];
}

- (void)performMigration {
    [self finishMigration];
}

- (BOOL)needsMigration {
    return NO;
}

- (void)updateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total {
    NSString* lineOne = MWLocalizedString(@"migration-update-progress-label", nil);

    NSString* lineTwo = MWLocalizedString(@"migration-update-progress-count-label", nil);

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%lu", (unsigned long)completed]];

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$2" withString:[NSString stringWithFormat:@"%lu", (unsigned long)total]];

    NSString* progressString = [NSString stringWithFormat:@"%@\n%@", lineOne, lineTwo];

    self.progressLabel.text = progressString;

    [self.progressIndicator setProgress:((float)completed / (float)total) animated:YES];
}

- (void)finishMigration {
    [[SessionSingleton sharedInstance].userDataStore reset];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES];
    [self dispatchCOmpletionBlockWithStatus:YES];
}

- (void)finishWithError:(NSError*)error {
    [self displayErrorCondition];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES];
    [self dispatchCOmpletionBlockWithStatus:YES];
}

- (void)displayErrorCondition {
    UIActionSheet* actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Migration failure: submit old data to developers to help diagnose?"];
    [actionSheet bk_setDestructiveButtonWithTitle:@"Discard old data" handler:^{
        [self dispatchCOmpletionBlockWithStatus:NO];
    }];
    [actionSheet bk_addButtonWithTitle:@"Submit to developers" handler:^{
        [self submitDataToDevs];
    }];

    [actionSheet showInView:self.view];
}

- (void)submitDataToDevs {
    MFMailComposeViewController* picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    picker.subject      = [NSString stringWithFormat:@"Feedback:%@", [WikipediaAppUtils versionedUserAgent]];
    picker.toRecipients = @[@"mobile-ios-wikipedia@wikimedia.org"];

    NSString* filename         = @"articleData6.sqlite";
    NSArray* documentPaths     = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = documentPaths[0];
    NSString* filePath         = [documentRootPath stringByAppendingPathComponent:filename];

    NSData* data = [NSData dataWithContentsOfFile:filePath];
    [picker addAttachmentData:data mimeType:@"application/octet-stream" fileName:filename];

    [picker setMessageBody:@"Attached data file is for internal development testing only." isHTML:NO];

    [self presentViewController:picker animated:YES completion:nil];
}

- (void)dispatchCOmpletionBlockWithStatus:(BOOL)completed {
    if (self.completionBlock) {
        self.completionBlock(completed);
    }
    self.completionBlock = NULL;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dispatchCOmpletionBlockWithStatus:NO];
}

@end
