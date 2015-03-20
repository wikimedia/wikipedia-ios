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

enum {
    BUTTON_INDEX_DISCARD = 0,
    BUTTON_INDEX_SUBMIT  = 1
} MigrationButtonIndexIds;

@interface DataMigrationProgressViewController ()

@property (readonly) OldDataSchemaMigrator* oldDataSchema;
@property (readonly) DataMigrator* dataMigrator;

@end

@implementation DataMigrationProgressViewController {
    OldDataSchemaMigrator* _oldDataSchema;
    DataMigrator* _dataMigrator;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.progressLabel.text = MWLocalizedString(@"update-progress-label", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self asyncMigration];
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

- (BOOL)needsMigration {
    return [self.oldDataSchema exists] || [self.dataMigrator hasData];
}

- (void)syncMigration {
    // Middle-Ages Converter
    // From the native app's initial CoreData-based implementation,
    // which now lives in OldDataSchema subproject.
    if ([self.oldDataSchema exists]) {
        SchemaConverter* schemaConverter = [[SchemaConverter alloc] initWithDataStore:[SessionSingleton sharedInstance].dataStore];
        self.oldDataSchema.delegate = schemaConverter;
        NSLog(@"begin migration");
        [self.oldDataSchema migrateData];
        NSLog(@"end migration");

        [self.oldDataSchema removeOldData];

        // hack for history fix
        [[SessionSingleton sharedInstance].userDataStore reset];

        return;
    }

    // Ye Ancient Converter
    // From the old PhoneGap app
    // @fixme: fix this to work again
    if ([self.dataMigrator hasData]) {
        NSLog(@"Old data to migrate found!");
        NSArray* titles           = [self.dataMigrator extractSavedPages];
        ArticleImporter* importer = [[ArticleImporter alloc] init];

        for (NSDictionary* item in titles) {
            NSLog(@"Will import saved page: %@ %@", item[@"lang"], item[@"title"]);
        }

        [importer importArticles:titles];

        [self.dataMigrator removeOldData];

        return;
    }

    NSLog(@"No old data to migrate.");
}

- (void)asyncMigration {
    __weak DataMigrationProgressViewController* weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        @try {
            [weakSelf syncMigration];
        }@catch (NSException* ex) {
            NSLog(@"Migration failure: %@", ex);
            dispatch_async(dispatch_get_main_queue(), ^() {
                [weakSelf displayErrorCondition];
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^() {
            [weakSelf.delegate dataMigrationProgressComplete:weakSelf];
        });
    });
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
