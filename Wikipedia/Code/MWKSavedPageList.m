#import "MWKSavedPageList.h"
#import "MWKDataStore+WMFDataSources.h"
#import <YapDataBase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>
#import "MWKHistoryEntry+WMFDatabaseStorable.h"
#import <WMFModel/WMFModel-Swift.h>

//Legacy
#import "MWKSavedPageListDataExportConstants.h"
#import "MWKSavedPageEntry.h"
NSString *const MWKSavedPageExportedEntriesKey = @"entries";
NSString *const MWKSavedPageExportedSchemaVersionKey = @"schemaVersion";

@interface MWKSavedPageList () <NSFetchedResultsControllerDelegate>

@property (readwrite, weak, nonatomic) MWKDataStore *dataStore;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MWKSavedPageList

#pragma mark - Setup

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        [self migrateLegacyDataIfNeeded];
        [self setupFetchedResultsController];
    }
    return self;
}


#pragma mark - Legacy Migration

- (MWKHistoryEntry *)historyEntryWithSavedPageEntry:(MWKSavedPageEntry *)entry {
    MWKHistoryEntry *history = [[MWKHistoryEntry alloc] initWithURL:entry.url];
    history.dateSaved = entry.date;
    return history;
}

- (void)migrateLegacyDataIfNeeded {
//    if ([[NSUserDefaults wmf_userDefaults] wmf_didMigrateSavedPageList]) {
//        return;
//    }
//
//    NSArray<MWKSavedPageEntry *> *entries =
//        [[MWKSavedPageList savedEntryDataFromExportedData:[self.dataStore savedPageListData]] wmf_mapAndRejectNil:^id(id obj) {
//            @try {
//                return [[MWKSavedPageEntry alloc] initWithDict:obj];
//            } @catch (NSException *e) {
//                return nil;
//            }
//        }];
//
//    if ([entries count] > 0) {
//        [self.dataSource readWriteAndReturnUpdatedKeysWithBlock:^NSArray<NSString *> *_Nonnull(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
//            NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[entries count]];
//            [entries enumerateObjectsUsingBlock:^(MWKSavedPageEntry *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//                if (obj.url.wmf_title.length == 0) {
//                    //HACK: Added check from pre-existing logic. Apparently there was a time when this URL could be bad. Copying here to keep exisitng functionality
//                    return;
//                }
//                MWKHistoryEntry *history = [self historyEntryWithSavedPageEntry:obj];
//                MWKHistoryEntry *existing = [transaction objectForKey:[history databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
//                if (existing) {
//                    existing.dateSaved = history.dateSaved;
//                    history = existing;
//                }
//                [transaction setObject:history forKey:[history databaseKey] inCollection:[MWKHistoryEntry databaseCollectionName]];
//                [urls addObject:[history databaseKey]];
//            }];
//            return urls;
//        }];
//
//        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateSavedPageList:YES];
//    }
}

- (void)setupFetchedResultsController {
    NSFetchRequest *articleRequest = [WMFArticle fetchRequest];
    articleRequest.predicate = [NSPredicate predicateWithFormat:@"savedDate != NULL"];
    articleRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"savedDate" ascending:NO]];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:articleRequest managedObjectContext:self.dataStore.viewContext sectionNameKeyPath:nil cacheName:@"org.wikipedia.saved"];
    frc.delegate = self;
    [frc performFetch:nil];
    self.fetchedResultsController = frc;
}

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems {
    return [[[self.fetchedResultsController sections] firstObject] numberOfObjects];
}

- (nullable WMFArticle *)mostRecentEntry {
    return (WMFArticle*)[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (nullable WMFArticle *)entryForURL:(NSURL *)url {
    NSString *key = [url wmf_articleDatabaseKey];
    if (!key) {
        return nil;
    }
    NSManagedObjectContext *moc = self.dataStore.viewContext;
    NSFetchRequest *request = [WMFArticle fetchRequest];
    [request setPredicate:[NSPredicate predicateWithFormat:@"key == %@ && savedDate != NULL", key]];
    NSArray<WMFArticle *> *results = [moc executeFetchRequest:request error:nil];
    return [results firstObject];
}

- (void)enumerateItemsWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block {
    if (!block) {
        return;
    }
    [[self.fetchedResultsController fetchedObjects] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, stop);
    }];
}

- (BOOL)isSaved:(NSURL *)url {
    if ([url.wmf_title length] == 0) {
        return NO;
    }
    return [self entryForURL:url] != nil;
}

#pragma mark - Update Methods

- (void)toggleSavedPageForURL:(NSURL *)url {
    if ([self isSaved:url]) {
        [self removeEntryWithURL:url];
    } else {
        [self addSavedPageWithURL:url];
    }
}


- (void)addSavedPageWithURL:(NSURL *)url {
    WMFArticle *article = [self.dataStore fetchOrCreateArticleWithURL:url];
    article.savedDate = [NSDate date];
    [self.dataStore save:nil];
}

- (void)removeEntryWithURL:(NSURL *)url {
    WMFArticle *article = [self.dataStore fetchArticleWithURL:url];
    if (!article) {
        return;
    }
    article.savedDate = nil;
    [self.dataStore save:nil];
}

- (void)removeAllEntries {
    [self enumerateItemsWithBlock:^(WMFArticle * _Nonnull entry, BOOL * _Nonnull stop) {
        entry.savedDate = nil;
    }];
    [self.dataStore save:nil];
}

#pragma mark - Legacy Schema Migration

+ (NSArray<NSDictionary *> *)savedEntryDataFromExportedData:(NSDictionary *)savedPageListData {
    NSNumber *schemaVersionValue = savedPageListData[MWKSavedPageExportedSchemaVersionKey];
    MWKSavedPageListSchemaVersion schemaVersion = MWKSavedPageListSchemaVersionUnknown;
    if (schemaVersionValue) {
        schemaVersion = schemaVersionValue.unsignedIntegerValue;
    }
    switch (schemaVersion) {
        case MWKSavedPageListSchemaVersionCurrent:
            return savedPageListData[MWKSavedPageExportedEntriesKey];
        case MWKSavedPageListSchemaVersionUnknown:
            return [MWKSavedPageList savedEntryDataFromListWithUnknownSchema:savedPageListData];
    }
}

+ (NSArray<NSDictionary *> *)savedEntryDataFromListWithUnknownSchema:(NSDictionary *)data {
    return [data[MWKSavedPageExportedEntriesKey] wmf_reverseArray];
}

#pragma mark - NSFetchedResultsControllerDelegate 

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    
}

/* Notifies the delegate of added or removed sections.  Enables NSFetchedResultsController change tracking.
 
	controller - controller instance that noticed the change on its sections
	sectionInfo - changed section
	index - index of changed section
	type - indicates if the change was an insert or delete
 
	Changes on section info are reported before changes on fetchedObjects.
 */
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
}

/* Notifies the delegate that section and object changes are about to be processed and notifications will be sent.  Enables NSFetchedResultsController change tracking.
 Clients may prepare for a batch of updates by using this method to begin an update block for their view.
 */
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
}

/* Notifies the delegate that all section and object changes have been sent. Enables NSFetchedResultsController change tracking.
 Clients may prepare for a batch of updates by using this method to begin an update block for their view.
 Providing an empty implementation will enable change tracking if you do not care about the individual callbacks.
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
}


@end
