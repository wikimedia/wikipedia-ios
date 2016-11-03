#import "WMFBaseDataStore.h"
#import "YapDatabase+WMFExtensions.h"
#import "YapDatabaseConnection+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFBaseDataStore ()

@property (readwrite, strong, nonatomic) YapDatabase *database;

@property (readwrite, strong, nonatomic) YapDatabaseConnection *readConnection;
@property (readwrite, strong, nonatomic) YapDatabaseConnection *writeConnection;

@property (readwrite, nonatomic, strong) NSPointerArray *changeHandlers;

@end

@implementation WMFBaseDataStore

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [self initWithDatabase:[YapDatabase sharedInstance]];
    return self;
}

- (instancetype)initWithDatabase:(YapDatabase *)database {
    NSParameterAssert(database);
    self = [super init];
    if (self) {
        self.databaseSyncingEnabled = YES;
        self.database = database;
        self.changeHandlers = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModified:)
                                                     name:YapDatabaseModifiedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModifiedExternally:)
                                                     name:YapDatabaseModifiedExternallyNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Database

- (YapDatabaseConnection *)readConnection {
    if (!_readConnection) {
        _readConnection = [self.database wmf_newLongLivedReadConnection];
    }
    return _readConnection;
}

- (YapDatabaseConnection *)writeConnection {
    if (!_writeConnection) {
        _writeConnection = [self.database wmf_newWriteConnection];
    }
    return _writeConnection;
}

#pragma mark - ChangeHandlers

- (void)registerChangeHandler:(id<WMFDatabaseChangeHandler>)handler {
    [self.changeHandlers addPointer:(__bridge void *_Nullable)(handler)];
}

#pragma mark - Read/Write

- (void)readWithBlock:(void (^)(YapDatabaseReadTransaction *_Nonnull transaction))block {
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        block(transaction);
    }];
}

- (nullable id)readAndReturnResultsWithBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction))block {
    return [self.readConnection wmf_readAndReturnResultsWithBlock:block];
}

- (void)readViewNamed:(NSString *)viewName withWithBlock:(void (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    [self.readConnection wmf_readInViewWithName:viewName withBlock:block];
}

- (nullable id)readAndReturnResultsWithViewNamed:(NSString *)viewName withWithBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block {
    return [self.readConnection wmf_readAndReturnResultsInViewWithName:viewName withBlock:block];
}

- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *_Nonnull transaction))block {
    [self.writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        block(transaction);
    }];
}

- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *_Nonnull transaction))block completion:(dispatch_block_t)completion {
    [self readWriteWithBlock:block];
    [self notifyWhenWriteTransactionsComplete:completion];
}

- (void)notifyWhenWriteTransactionsComplete:(nullable dispatch_block_t)completion {
    [self.writeConnection flushTransactionsWithCompletionQueue:dispatch_get_main_queue() completionBlock:completion];
}

#pragma mark - YapDatabaseModified Notification

- (void)setDatabaseSyncingEnabled:(BOOL)databaseSyncingEnabled {
    _databaseSyncingEnabled = databaseSyncingEnabled;
    if (_databaseSyncingEnabled) {
        [self syncDataStoreToDatabase];
    }
}

- (void)yapDatabaseModifiedExternally:(NSNotification *)notification {
    [self yapDatabaseModified:notification];
}

- (void)yapDatabaseModified:(NSNotification *)notification {
    if (!self.databaseSyncingEnabled) {
        return;
    }
    [self syncDataStoreToDatabase];
    [self dataStoreWasUpdatedWithNotification:notification];
}

- (void)syncDataStoreToDatabase {
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    NSArray *notifications = [self.readConnection beginLongLivedReadTransaction];

    //Note: we must send notificatons even if they are 0
    //This is neccesary because when changes happen in other processes
    //Yap reports 0 changes and simply flushes its caches.
    //This updates the connections and the DB, but not mappings
    //To update any mappings, we must propagate "0" notifications

    [self.changeHandlers compact];
    for (id<WMFDatabaseChangeHandler> obj in self.changeHandlers) {
        [obj processChanges:notifications onConnection:self.readConnection];
    }
}

- (void)dataStoreWasUpdatedWithNotification:(NSNotification *)notification {
}

@end

NS_ASSUME_NONNULL_END
