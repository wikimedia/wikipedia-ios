//
//  DataMigrationProgress.m
//  Wikipedia
//
//  Created by Brion on 1/13/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "DataMigrationProgressViewController.h"

#import "SessionSingleton.h"

#import "OldDataSchemaMigrator.h"
#import "SchemaConverter.h"

#import "DataMigrator.h"
#import "ArticleImporter.h"

#import "WikipediaAppUtils.h"
#import "WMFProgressLineView.h"

enum {
    BUTTON_INDEX_DISCARD = 0,
    BUTTON_INDEX_SUBMIT  = 1
} MigrationButtonIndexIds;

@interface DataMigrationProgressViewController ()<OldDataSchemaMigratorProgressDelegate>

@property (nonatomic, strong) SchemaConverter* schemaConvertor;
@property (nonatomic, strong) OldDataSchemaMigrator* oldDataSchema;
@property (nonatomic, strong) DataMigrator* dataMigrator;

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
    } else if ([self.dataMigrator hasData]) {
        [self runOldMigration];
    }
}

- (OldDataSchemaMigrator*)oldDataSchema {
    if (_oldDataSchema == nil) {
        _oldDataSchema = [[OldDataSchemaMigrator alloc] init];
    }
    return _oldDataSchema;
}

- (DataMigrator*)dataMigrator {
    if (_dataMigrator == nil) {
        _dataMigrator = [[DataMigrator alloc] init];
    }
    return _dataMigrator;
}

- (SchemaConverter*)schemaConvertor {
    if (!_schemaConvertor) {
        _schemaConvertor = [[SchemaConverter alloc] initWithDataStore:[SessionSingleton sharedInstance].dataStore];
    }
    return _schemaConvertor;
}

- (BOOL)needsMigration {
    return [self.oldDataSchema exists] || [self.dataMigrator hasData];
}

- (void)runNewMigration {
    // Middle-Ages Converter
    // From the native app's initial CoreData-based implementation,
    // which now lives in OldDataSchema subproject.

    self.progressIndicator.progress = 0.0;

    self.oldDataSchema.delegate         = self.schemaConvertor;
    self.oldDataSchema.progressDelegate = self;
    NSLog(@"begin migration");
    [self.oldDataSchema migrateData];
}

- (void)runOldMigration {
    // Ye Ancient Converter
    // From the old PhoneGap app
    // @fixme: fix this to work again

    self.progressIndicator.progress = 0.0;

    NSLog(@"Old data to migrate found!");
    NSArray* titles           = [self.dataMigrator extractSavedPages];
    ArticleImporter* importer = [[ArticleImporter alloc] init];

    for (NSDictionary* item in titles) {
        NSLog(@"Will import saved page: %@ %@", item[@"lang"], item[@"title"]);
    }

    [importer importArticles:titles];

    [self.dataMigrator removeOldData];

    [self.progressIndicator setProgress:1.0 animated:YES completion:NULL];
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema didUpdateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total {
    NSString* lineOne = MWLocalizedString(@"migration-update-progress-label", nil);

    NSString* lineTwo = MWLocalizedString(@"migration-update-progress-count-label", nil);

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$1" withString:[NSString stringWithFormat:@"%lu", (unsigned long)completed]];

    lineTwo = [lineTwo stringByReplacingOccurrencesOfString:@"$2" withString:[NSString stringWithFormat:@"%lu", (unsigned long)total]];

    NSString* progressString = [NSString stringWithFormat:@"%@\n%@", lineOne, lineTwo];

    self.progressLabel.text = progressString;

    [self.progressIndicator setProgress:((float)completed / (float)total) animated:YES];
}

- (void)oldDataSchemaDidFinishMigration:(OldDataSchemaMigrator*)schema {
    [[SessionSingleton sharedInstance].userDataStore reset];
    NSLog(@"end migration");

    [self.progressIndicator setProgress:1.0 animated:YES completion:^{
        [self.delegate dataMigrationProgressComplete:self];
    }];
}

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema didFinishWithError:(NSError*)error {
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
    picker.mailComposeDelegate = self; //

    picker.subject      = @"Wikipedia iOS app data migration failure";
    picker.toRecipients = @[@"bvibber@wikimedia.org"]; // @fixme do we have a better place to send these?

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
