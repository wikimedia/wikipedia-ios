#import <Foundation/Foundation.h>

@class YapDatabase;
@class YapDatabaseConnection;
@class YapDatabaseViewRowChange;
@class YapDatabaseReadTransaction;
@class YapDatabaseReadWriteTransaction;
@class YapDatabaseViewTransaction;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFDatabaseChangeHandler <NSObject>

- (void)processChanges:(NSArray *)changes onConnection:(YapDatabaseConnection *)connection;

@end

@interface WMFBaseDataStore : NSObject

/**
 *  Initialize with sharedInstance database 
 *
 *  @return A data store
 */
- (instancetype)init;

- (instancetype)initWithDatabase:(YapDatabase *)database NS_DESIGNATED_INITIALIZER;

@property (readonly, strong, nonatomic) YapDatabase *database;

/*
 * Updates from databse processed automatically. Default = YES
 */
@property (assign, nonatomic) BOOL databaseSyncingEnabled;

/**
 *  Call this to manually sync the database.
 *  Useful for when resuming and the DB may have been modified out of process
 */
- (void)syncDataStoreToDatabase;

- (void)registerChangeHandler:(id<WMFDatabaseChangeHandler>)handler;

- (void)readWithBlock:(void (^)(YapDatabaseReadTransaction *_Nonnull transaction))block;

- (nullable id)readAndReturnResultsWithBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction))block;
- (void)readViewNamed:(NSString *)viewName withWithBlock:(void (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block;
- (nullable id)readAndReturnResultsWithViewNamed:(NSString *)viewName withWithBlock:(id (^)(YapDatabaseReadTransaction *_Nonnull transaction, YapDatabaseViewTransaction *_Nonnull view))block;

- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *_Nonnull transaction))block;

- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *_Nonnull transaction))block completion:(dispatch_block_t)completion;

- (void)notifyWhenWriteTransactionsComplete:(nullable dispatch_block_t)completion;

@end

@interface WMFBaseDataStore (WMFSubclasses)

@property (readonly, strong, nonatomic) YapDatabaseConnection *readConnection;
@property (readonly, strong, nonatomic) YapDatabaseConnection *writeConnection;

- (void)dataStoreWasUpdatedWithNotification:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
