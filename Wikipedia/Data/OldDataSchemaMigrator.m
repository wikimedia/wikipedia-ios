
#import "OldDataSchemaMigrator_Private.h"
#import "ArticleCoreDataObjects.h"
#import "NSDateFormatter+WMFExtensions.h"
#import "NSManagedObjectContext+SimpleFetch.h"
#import "Article+ConvenienceAccessors.h"

static NSString* const kWMFOldDataSchemaBackupDateKey               = @"kWMFOldDataSchemaBackupDateKey";
static NSUInteger const kWMFOldDataSchemaBackupExpirationTimeInDays = 30;


@interface OldDataSchemaMigrator ()

@property (nonatomic, strong, readwrite) NSString* databasePath;

@property (nonatomic, strong) NSMutableSet* savedTitles;

@end

@implementation OldDataSchemaMigrator

- (instancetype)initWithDatabasePath:(NSString*)databasePath {
    self = [super init];
    if (self) {
        self.savedTitles  = [[NSMutableSet alloc] init];
        self.databasePath = databasePath;
    }
    return self;
}

- (NSString*)backupDatabasePath {
    return [self.databasePath stringByAppendingString:@".bak"];
}

- (BOOL)exists {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.databasePath];
}

- (BOOL)backupExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self backupDatabasePath]];
}

- (BOOL)moveOldDataToBackupLocation {
    NSError* err = nil;

    if ([[NSFileManager defaultManager] moveItemAtPath:self.databasePath
                                                toPath:[self backupDatabasePath]
                                                 error:&err]) {
        [self setBackDateToNow];
        return YES;
    } else {
        NSLog(@"Error backing up %@: %@", self.databasePath, err);
        return NO;
    }
}

- (BOOL)removeOldDataIfOlderThanMaximumGracePeriod {
    [self setBackupDateForPreexistingBackups];

    if ([self shouldRemoveBackup]) {
        return [self removebackupDataImmediately];
    }

    return NO;
}

- (BOOL)removebackupDataImmediately {
    NSError* error = nil;

    if ([[NSFileManager defaultManager] removeItemAtPath:[self backupDatabasePath] error:&error]) {
        return YES;
    } else {
        NSLog(@"Error removing backup %@: %@", [self backupDatabasePath], [error localizedDescription]);
        return NO;
    }
}

- (void)setBackDateToNow {
    NSDate* backupDate = [NSDate new];
    [[NSUserDefaults standardUserDefaults] setDouble:backupDate.timeIntervalSinceReferenceDate forKey:kWMFOldDataSchemaBackupDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setBackupDateForPreexistingBackups {
    if (([[NSUserDefaults standardUserDefaults] doubleForKey:kWMFOldDataSchemaBackupDateKey] < 1.0) && [self backupExists]) {
        [self setBackDateToNow];
    }
}

- (BOOL)shouldRemoveBackup {
    NSTimeInterval backupTimeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kWMFOldDataSchemaBackupDateKey];
    if (backupTimeInterval < 1.0) {
        return NO;
    }

    NSDate* backupDate = [NSDate dateWithTimeIntervalSinceReferenceDate:backupTimeInterval];

    NSTimeInterval backupExpiraton = kWMFOldDataSchemaBackupExpirationTimeInDays * 24 * 60 * 60;

    if ([[NSDate new] timeIntervalSinceDate:backupDate] > backupExpiraton) {
        return YES;
    }

    return NO;
}

- (void)migrateData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![self migrateHistory]) {
        }

        if (![self migrateSavedPages]) {
        }

        [self moveOldDataToBackupLocation];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressDelegate oldDataSchemaDidFinishMigration:self];
        });
    });
}

- (BOOL)migrateHistory {
    __block NSError* error;

    [self.context performBlockAndWait:^{
        NSFetchRequest* req2 = [NSFetchRequest fetchRequestWithEntityName:@"History"];
        req2.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:YES]];
        NSArray* historyEntries = [self.context executeFetchRequest:req2 error:&error];

        if (error) {
            NSLog(@"Error reading old History entries: %@", error);
        }

        for (History* history in historyEntries) {
            @autoreleasepool {
                [self migrateHistory:history];
            }
        }

        [self.context reset];
    }];


    return error == nil;
}

- (BOOL)migrateSavedPages {
    __block NSError* error;
    __block NSUInteger totalArticlesToMigrate   = 0;
    __block NSUInteger numberOfArticlesMigrated = 0;

    [self.context performBlockAndWait:^{
        NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Saved"];
        req.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dateSaved" ascending:YES]];
        totalArticlesToMigrate = [self.context countForFetchRequest:req error:&error];
        NSLog(@"total articles: %lu", totalArticlesToMigrate);
    }];

    NSUInteger fetchSize                   = 25;
    __block BOOL moreSavedEntriesToProcess = YES;
    __block NSUInteger fetchOffset         = 0;

    if (totalArticlesToMigrate > 0) {
        while (moreSavedEntriesToProcess) {
            NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Saved"];
            req.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dateSaved" ascending:YES]];
            req.fetchLimit      = fetchSize;
            req.fetchOffset     = fetchOffset;

            [self.context performBlock:^{
                NSError* innerError;
                NSArray* savedEntries = [self.context executeFetchRequest:req error:&innerError];

                if (savedEntries) {
                    for (Saved* saved in savedEntries) {
                        @autoreleasepool {
                            [self migrateSaved:saved];
                            [self migrateArticle:saved.article];
                            numberOfArticlesMigrated++;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.progressDelegate oldDataSchema:self didUpdateProgressWithArticlesCompleted:numberOfArticlesMigrated total:totalArticlesToMigrate];
                            });
                        }
                    }
                } else {
                    error = innerError;
                    NSLog(@"Error reading old Saved entries: %@", error);
                }

                [self.context reset];
            }];

            NSUInteger indexOfLastArticleMigrated = fetchOffset + fetchSize - 1;
            NSUInteger indexOfLastArticle         = totalArticlesToMigrate - 1;

            if (indexOfLastArticleMigrated < indexOfLastArticle) {
                fetchOffset += fetchSize;
            } else {
                moreSavedEntriesToProcess = NO;
            }
        }
    }

    //Wait on the context to finish the above operations.
    //We need to do this because we need the above calls to be async so we can
    //call back to the main thread to update the UI
    [self.context performBlockAndWait:^{
    }];

    return error == nil;
}

- (MWKSite*)migrateArticleSite:(Article*)article {
    return [[MWKSite alloc] initWithDomain:@"wikipedia.org" language:article.domain];
}

- (MWKTitle*)migrateArticleTitle:(Article*)article {
    return [[self migrateArticleSite:article] titleWithString:article.title];
}

- (void)migrateSaved:(Saved*)saved {
    NSDictionary* dict = [self exportSaved:saved];
    [self.delegate oldDataSchema:self migrateSavedEntry:dict];
}

- (void)migrateHistory:(History*)history {
    NSDictionary* dict = [self exportHistory:history];
    [self.delegate oldDataSchema:self migrateHistoryEntry:dict];
}

- (void)migrateArticle:(Article*)article {
    NSString* key = [NSString stringWithFormat:@"%@:%@", article.domain, article.title];
    if ([self.savedTitles containsObject:key]) {
        // already imported this article
    } else {
        // Record for later to avoid dupe imports
        [self.savedTitles addObject:key];

        MWKArticle* migratedArticle;
        @try {
            migratedArticle = [self.delegate oldDataSchema:self migrateArticle:[self exportArticle:article]];

            Image* thumbnail = article.thumbnailImage;
            if (thumbnail) {
                [self migrateThumbnailImage:thumbnail article:article newArticle:migratedArticle];
            }
            // HACK: setting thumbnailURL after migration prevents it from being added to the image list twice
            migratedArticle.thumbnailURL = thumbnail.sourceUrl;

            for (Section* section in [article sectionsBySectionId]) {
                for (SectionImage* sectionImage in [section sectionImagesByIndex]) {
                    [self migrateImage:sectionImage newArticle:migratedArticle];
                }
            }

            // set the lead image to the first non-thumb image
            if ([migratedArticle.images count]) {
                // thumbnail should always be first, if it's present (see above assertion)
                NSUInteger leadImageURLIndex = (thumbnail && migratedArticle.images.count > 1) ? 1 : 0;
                migratedArticle.imageURL = [migratedArticle.images imageURLAtIndex:leadImageURLIndex];
            }

            [migratedArticle save];
        }@catch (NSException* exception) {
            NSLog(@"Failed to migrate article due to exception: %@. Removing data.", exception);
            [migratedArticle remove];
        }
    }
}

- (void)migrateThumbnailImage:(Image*)thumbnailImage article:(Article*)article newArticle:(MWKArticle*)newArticle {
    NSDictionary* dict = [self exportThumbnailImage:thumbnailImage article:article];
    [self.delegate oldDataSchema:self migrateImage:dict newArticle:newArticle];
}

- (void)migrateImage:(SectionImage*)sectionImage newArticle:(MWKArticle*)newArticle {
    NSDictionary* dict = [self exportImage:sectionImage];
    [self.delegate oldDataSchema:self migrateImage:dict newArticle:newArticle];
}

- (NSDictionary*)exportSaved:(Saved*)saved {
    return @{
               @"domain": @"wikipedia.org",
               @"language": saved.article.domain,
               @"title": saved.article.title,
               @"date": [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:saved.dateSaved]
    };
}

- (NSDictionary*)exportHistory:(History*)history {
    return @{
               @"domain": @"wikipedia.org",
               @"language": history.article.domain,
               @"title": history.article.title,
               @"date": [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:history.dateVisited],
               @"discoveryMethod": history.discoveryMethod,
               @"scrollPosition": history.article.lastScrollY
    };
}

- (NSDictionary*)exportArticle:(Article*)article {
    NSParameterAssert(article);
    NSMutableDictionary* dict = [@{} mutableCopy];

    if (article.redirected) {
        dict[@"redirected"] = article.redirected;
    }
    if (article.lastmodified) {
        dict[@"lastmodified"] = [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:article.lastmodified];
    }
    if (article.lastmodifiedby) {
        dict[@"lastmodifiedby"] = @{
            @"name": article.lastmodifiedby,
            @"gender": @"unknown"
        };
    }
    if (article.articleId) {
        dict[@"id"] = article.articleId;
    }
    if (article.languagecount) {
        dict[@"languagecount"] = article.languagecount;
    }
    if (article.displayTitle) {
        dict[@"displaytitle"] = article.displayTitle;
    }
    if (article.protectionStatus) {
        dict[@"protection"] = @{
            @"edit": @[article.protectionStatus]
        };
    }
    if (article.editable) {
        dict[@"editable"] = article.editable;
    }

    // sections!
    NSUInteger numSections = [article.section count];
    if (numSections) {
        dict[@"sections"] = [[NSMutableArray alloc] initWithCapacity:numSections];
        for (int i = 0; i < numSections; i++) {
            dict[@"sections"][i] = [NSNull null]; // stub out
        }
        for (Section* section in article.section) {
            int sectionId = [section.sectionId intValue];
            dict[@"sections"][sectionId] = [self exportSection:section];
        }
    }

    return @{
               @"language": article.domain,
               @"title": article.title,
               @"dict": dict
    };
}

- (NSDictionary*)exportSection:(Section*)section {
    NSParameterAssert(section);
    NSMutableDictionary* dict = [@{} mutableCopy];

    if (section.tocLevel) {
        dict[@"toclevel"] = section.tocLevel;
    }
    if (section.level) {
        dict[@"level"] = section.level;
    }
    if (section.title) {
        dict[@"line"] = section.title;
    }
    if (section.fromTitle) {
        dict[@"fromtitle"] = section.fromTitle;
    }
    if (section.anchor) {
        dict[@"anchor"] = section.anchor;
    }
    dict[@"id"] = section.sectionId;
    if (section.html) {
        dict[@"text"] = section.html;
    }

    return dict;
}

- (NSDictionary*)exportThumbnailImage:(Image*)image article:(Article*)article {
    NSParameterAssert(image);
    NSParameterAssert(article);
    ImageData* imageData = image.imageData;

    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"domain"]   = @"wikipedia.org";
    dict[@"language"] = article.domain;
    dict[@"title"]    = article.title;

    dict[@"sectionId"] = @(-1);

    dict[@"sourceURL"] = image.sourceUrl;
    if (imageData.data) {
        dict[@"data"] = imageData.data;
    }

    return dict;
}

- (NSDictionary*)exportImage:(SectionImage*)sectionImage {
    NSParameterAssert(sectionImage);
    Section* section     = sectionImage.section;
    Article* article     = section.article;
    Image* image         = sectionImage.image;
    ImageData* imageData = image.imageData;

    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"domain"]   = @"wikipedia.org";
    dict[@"language"] = article.domain;
    dict[@"title"]    = article.title;

    dict[@"sectionId"] = section.sectionId;

    dict[@"sourceURL"] = image.sourceUrl;
    if (imageData.data) {
        dict[@"data"] = imageData.data;
    }

    return dict;
}

@end
