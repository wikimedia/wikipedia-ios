
#import "DataMigrationProgressViewController.h"

#import "SessionSingleton.h"

#import "LegacyCoreDataMigrator.h"
#import "LegacyDataMigrator.h"

#import "LegacyPhoneGapDataMigrator.h"

#import "WikipediaAppUtils.h"
#import "ArticleDataContextSingleton.h"

#import <BlocksKit/BlocksKit+UIKit.h>

typedef NS_ENUM (NSInteger, MigrationButtonIndexIds) {
    BUTTON_INDEX_DISCARD = 0,
    BUTTON_INDEX_SUBMIT  = 1
};

@interface DataMigrationProgressViewController ()<LegacyCoreDataMigratorProgressDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) WMFDataMigrationCompletionBlock completionBlock;

@property (nonatomic, strong) LegacyDataMigrator* schemaConvertor;
@property (nonatomic, strong) LegacyCoreDataMigrator* oldDataSchema;

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
        [self moveOldDataToBackupLocation];
        [self dispatchCOmpletionBlockWithStatus:NO];
    }];
    [dialog bk_addButtonWithTitle:MWLocalizedString(@"migration-confirm-button-title", nil) handler:^{
        [self performMigration];
    }];

    [dialog show];
}

- (void)performMigration {
    if ([self.oldDataSchema exists]) {
        [self runNewMigration];
    }
    // FIXME: ask user to reach out to devs for assistance with migrating their data
    // else if ([LegacyPhoneGapDataMigrator hasData]) {
    //
    // }
}

- (LegacyCoreDataMigrator*)oldDataSchema {
    if (_oldDataSchema == nil) {
        ArticleDataContextSingleton* context = [ArticleDataContextSingleton sharedInstance];
        _oldDataSchema = [[LegacyCoreDataMigrator alloc] initWithDatabasePath:context.databasePath];
    }
    return _oldDataSchema;
}

- (LegacyDataMigrator*)schemaConvertor {
    if (!_schemaConvertor) {
        _schemaConvertor = [[LegacyDataMigrator alloc] initWithDataStore:[SessionSingleton sharedInstance].dataStore];
    }
    return _schemaConvertor;
}

- (BOOL)needsMigration {
    return [self.oldDataSchema exists];
}

- (void)moveOldDataToBackupLocation {
    [self.oldDataSchema moveOldDataToBackupLocation];
}

- (void)removeOldDataBackupIfNeeded {
    [self.oldDataSchema removeOldDataIfOlderThanMaximumGracePeriod];
}

- (void)runNewMigration {
    // Middle-Ages Converter
    // From the native app's initial CoreData-based implementation,
    // which now lives in LegacyCoreData subproject.

    self.progressIndicator.progress       = 0.0;
    self.progressIndicator.trackTintColor = [UIColor clearColor];
    self.progressIndicator.tintColor      = [UIColor wmf_blueTintColor];

    self.oldDataSchema.delegate         = self.schemaConvertor;
    self.oldDataSchema.progressDelegate = self;
    self.oldDataSchema.context          = [[ArticleDataContextSingleton sharedInstance] backgroundContext];
    NSLog(@"begin migration");
    [self.oldDataSchema migrateData];
}

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema didUpdateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total {
    NSString* lineOne = MWLocalizedString(@"migration-update-progress-label", nil);

    NSString* lineTwo = MWLocalizedString(@"migration-update-progress-count-label", nil);

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%lu", (unsigned long)completed]];

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$2" withString:[NSString stringWithFormat:@"%lu", (unsigned long)total]];

    NSString* progressString = [NSString stringWithFormat:@"%@\n%@", lineOne, lineTwo];

    self.progressLabel.text = progressString;

    [self.progressIndicator setProgress:((float)completed / (float)total) animated:YES];
}

- (void)oldDataSchemaDidFinishMigration:(LegacyCoreDataMigrator*)schema {
    [[SessionSingleton sharedInstance].userDataStore reset];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES];
    [self dispatchCOmpletionBlockWithStatus:YES];
}

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema didFinishWithError:(NSError*)error {
    [self displayErrorCondition];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES];
    [self dispatchCOmpletionBlockWithStatus:YES];
}

- (void)displayErrorCondition {
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:@"Migration failure: submit old data to developers to help diagnose?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Discard old data" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* _Nonnull action) {
        [self dispatchCOmpletionBlockWithStatus:NO];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Submit to developers" style:UIAlertActionStyleDefault handler:^(UIAlertAction* _Nonnull action) {
        [self submitDataToDevs];
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
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
