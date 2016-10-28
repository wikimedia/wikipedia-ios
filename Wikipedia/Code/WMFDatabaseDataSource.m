#import "WMFDatabaseDataSource.h"
#import <YapDatabase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>
#import "YapDatabaseConnection+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFDatabaseDataSource ()

@property (readwrite, weak, nonatomic) YapDatabaseConnection *readConnection;
@property (readwrite, weak, nonatomic) YapDatabaseConnection *writeConnection;

@property (readonly, strong, nonatomic) NSString *viewName;

@property (readwrite, strong, nonatomic) YapDatabaseViewMappings *mappings;

@end

@implementation WMFDatabaseDataSource

@synthesize delegate;
@synthesize granularDelegateCallbacksEnabled;

- (instancetype)initWithReadConnection:(YapDatabaseConnection *)readConnection writeConnection:(YapDatabaseConnection *)writeConnection mappings:(YapDatabaseViewMappings *)mappings {
    NSParameterAssert(readConnection);
    NSParameterAssert(writeConnection);
    NSParameterAssert(mappings);
    self = [super init];
    if (self) {
        self.readConnection = readConnection;
        self.writeConnection = writeConnection;
        self.mappings = mappings;

        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            //HACK: you mush access the view prior to updating the mappins of the view will be in an inconsistent state: see link
            [transaction ext:self.viewName];
            [self.mappings updateWithTransaction:transaction];
        }];
    }
    return self;
}

- (NSString *)viewName {
    return self.mappings.view;
}

#pragma mark - Table/Collection View Methods

- (NSInteger)numberOfItems {
    return [self.mappings numberOfItemsInAllGroups];
}

- (NSInteger)numberOfSections {
    return [self.mappings numberOfSections];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [self.mappings numberOfItemsInSection:section];
}

- (nullable NSString *)titleForSectionIndex:(NSInteger)index {
    NSString *text = [self.mappings groupForSection:index];
    return text;
}

- (nullable id<WMFDatabaseStorable>)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        return [view objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
}

- (nullable id)metadataAtIndexPath:(NSIndexPath *)indexPath {
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view) {
        return [view metadataAtIndexPath:indexPath withMappings:self.mappings];
    }];
}

- (NSIndexPath*)indexPathForObject:(id<WMFDatabaseStorable>)object{
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction * _Nonnull transaction, YapDatabaseViewTransaction * _Nonnull view) {
        return [view indexPathForKey:[object databaseKey] inCollection:[[object class] databaseCollectionName] withMappings:self.mappings];
    }];
}


- (void)processChanges:(NSArray *)changes onConnection:(YapDatabaseConnection *)connection {
    if (![connection isEqual:self.readConnection]) {
        return;
    }

    //This is neccesary because when changes happen in other processes
    //Yap reports 0 changes and simply flushes its caches.
    //This updates the connections and the DB, but not the mappings
    //To update the mappings, we must explicitly do it here
    //Although there are legitimate reasons we get 0 changes,
    //which could be safely ignored, there is no way to differentiate
    //between those reasons and when modifications happen in extensions
    if (!self.areGranularDelegateCallbacksEnabled || [changes count] == 0 || self.mappings.snapshotOfLastUpdate != connection.snapshot - 1) {

        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.mappings updateWithTransaction:transaction];
        }];

        [self.delegate dataSourceDidUpdateAllData:self];

        return;
    }

    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;

    [[self.readConnection ext:self.viewName] getSectionChanges:&sectionChanges
                                                    rowChanges:&rowChanges
                                              forNotifications:changes
                                                  withMappings:self.mappings];

    if ([sectionChanges count] == 0 & [rowChanges count] == 0) {
        return;
    }

    if (!self.delegate) {

        return;
    }

    if ([self.delegate respondsToSelector:@selector(dataSourceWillBeginUpdates:)]) {
        [self.delegate dataSourceWillBeginUpdates:self];
    }

    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges) {
        switch (sectionChange.type) {
            case YapDatabaseViewChangeDelete: {
                if ([self.delegate respondsToSelector:@selector(dataSource:didDeleteSectionsAtIndexes:)]) {
                    [self.delegate dataSource:self didDeleteSectionsAtIndexes:[NSIndexSet indexSetWithIndex:sectionChange.index]];
                }
                break;
            }
            case YapDatabaseViewChangeInsert: {
                if ([self.delegate respondsToSelector:@selector(dataSource:didInsertSectionsAtIndexes:)]) {
                    [self.delegate dataSource:self didInsertSectionsAtIndexes:[NSIndexSet indexSetWithIndex:sectionChange.index]];
                }
                break;
            }
            default: {
                //no other possible cases
            }
        }
    }

    for (YapDatabaseViewRowChange *rowChange in rowChanges) {
        switch (rowChange.type) {
            case YapDatabaseViewChangeDelete: {
                if ([self.delegate respondsToSelector:@selector(dataSource:didDeleteRowsAtIndexPaths:)]) {
                    [self.delegate dataSource:self didDeleteRowsAtIndexPaths:@[rowChange.indexPath]];
                }
                break;
            }
            case YapDatabaseViewChangeInsert: {
                if ([self.delegate respondsToSelector:@selector(dataSource:didInsertRowsAtIndexPaths:)]) {
                    [self.delegate dataSource:self didInsertRowsAtIndexPaths:@[rowChange.newIndexPath]];
                }
                break;
            }
            case YapDatabaseViewChangeMove: {
                if ([self.delegate respondsToSelector:@selector(dataSource:didMoveRowFromIndexPath:toIndexPath:)]) {
                    [self.delegate dataSource:self didMoveRowFromIndexPath:rowChange.indexPath toIndexPath:rowChange.newIndexPath];
                }
                break;
            }
            case YapDatabaseViewChangeUpdate: {
                if ([self.delegate respondsToSelector:@selector(dataSource:didUpdateRowsAtIndexPaths:)]) {
                    [self.delegate dataSource:self didUpdateRowsAtIndexPaths:@[rowChange.indexPath]];
                }
                break;
            }
        }
    }

    if ([self.delegate respondsToSelector:@selector(dataSourceDidFinishUpdates:)]) {
        [self.delegate dataSourceDidFinishUpdates:self];
    }
}

#pragma mark - Read

- (void)readWithBlock:(void (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    [self.readConnection wmf_readInViewWithName:self.mappings.view withBlock:block];
}

- (nullable id)readAndReturnResultsWithBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    return [self.readConnection wmf_readAndReturnResultsInViewWithName:self.mappings.view withBlock:block];
}

- (void)readWriteAndReturnUpdatedKeysWithBlock:(NSArray<NSString *> * (^)(YapDatabaseReadWriteTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    [self.writeConnection wmf_readWriteAndReturnUpdatedKeysInViewWithName:self.mappings.view withBlock:block];
}

@end

NS_ASSUME_NONNULL_END
