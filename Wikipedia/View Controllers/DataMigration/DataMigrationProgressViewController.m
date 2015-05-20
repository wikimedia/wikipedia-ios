
#import "DataMigrationProgressViewController.h"

#import "SessionSingleton.h"

#import "LegacyCoreDataMigrator.h"
#import "LegacyDataMigrator.h"

#import "LegacyPhoneGapDataMigrator.h"

#import "WikipediaAppUtils.h"
#import "WMFProgressLineView.h"
#import "ArticleDataContextSingleton.h"

enum {
    BUTTON_INDEX_DISCARD = 0,
    BUTTON_INDEX_SUBMIT  = 1
} MigrationButtonIndexIds;

@interface DataMigrationProgressViewController ()<LegacyCoreDataMigratorProgressDelegate>

@property (nonatomic, strong) LegacyDataMigrator* schemaConvertor;
@property (nonatomic, strong) LegacyCoreDataMigrator* oldDataSchema;
@property (nonatomic, strong) LegacyPhoneGapDataMigrator* dataMigrator;

@end

@implementation DataMigrationProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.progressLabel.text = MWLocalizedString(@"migration-update-progress-label", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

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

- (LegacyPhoneGapDataMigrator*)dataMigrator {
    if (_dataMigrator == nil) {
        _dataMigrator = [[LegacyPhoneGapDataMigrator alloc] init];
    }
    return _dataMigrator;
}

- (LegacyDataMigrator*)schemaConvertor {
    if (!_schemaConvertor) {
        _schemaConvertor = [[LegacyDataMigrator alloc] initWithDataStore:[SessionSingleton sharedInstance].dataStore];
    }
    return _schemaConvertor;
}

- (BOOL)needsMigration {
    return [self.oldDataSchema exists] || [LegacyPhoneGapDataMigrator hasData];
}

- (void)moveOldDataToBackupLocation {
    [LegacyPhoneGapDataMigrator removeOldData]; //we do not back old old data
    [self.oldDataSchema moveOldDataToBackupLocation];
}

- (void)removeOldDataBackupIfNeeded {
    [self.oldDataSchema removeOldDataIfOlderThanMaximumGracePeriod];
}

- (void)runNewMigration {
    // Middle-Ages Converter
    // From the native app's initial CoreData-based implementation,
    // which now lives in LegacyCoreData subproject.

    self.progressIndicator.progress = 0.0;

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

    [self.progressIndicator setProgress:1.0 animated:YES completion:^{
        [self.delegate dataMigrationProgressComplete:self];
    }];
}

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema didFinishWithError:(NSError*)error {
    [self displayErrorCondition];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES completion:^{
        [self.delegate dataMigrationProgressComplete:self];
    }];
}

- (void)displayErrorCondition {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Migration failure: submit old data to developers to help diagnose?"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:@"Discard old data"
                                                    otherButtonTitles:@"Submit to developers", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSLog(@"%d", (int)buttonIndex);
    switch (buttonIndex) {
        case BUTTON_INDEX_DISCARD: // discard old data
            [self.delegate dataMigrationProgressComplete:self];
            break;
        case BUTTON_INDEX_SUBMIT: // submit data
            [self submitDataToDevs];
            break;
    }
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

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self.delegate dataMigrationProgressComplete:self];
}

@end
