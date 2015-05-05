
#import <Foundation/Foundation.h>


@class OldDataSchemaMigrator, MWKArticle, MWKTitle, MWKImage;

@protocol OldDataSchemaDelegate

- (MWKArticle*)oldDataSchema:(OldDataSchemaMigrator*)schema migrateArticle:(NSDictionary*)articleDict;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema
         migrateImage:(NSDictionary*)imageDict
           newArticle:(MWKArticle*)newArticle;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema migrateHistoryEntry:(NSDictionary*)historyDict;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema migrateSavedEntry:(NSDictionary*)savedDict;

@end

@protocol OldDataSchemaMigratorProgressDelegate <NSObject>

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema didUpdateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total;

- (void)oldDataSchemaDidFinishMigration:(OldDataSchemaMigrator*)schema;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema didFinishWithError:(NSError*)error;

@end



@interface OldDataSchemaMigrator : NSObject

@property (weak) id<OldDataSchemaDelegate> delegate;
@property (weak) id<OldDataSchemaMigratorProgressDelegate> progressDelegate;

- (instancetype)initWithDatabasePath:(NSString*)databasePath;

@property (nonatomic, strong, readonly) NSString* databasePath;
@property (nonatomic, strong, readonly) NSString* backupDatabasePath;

/**
 *  Does the database exist
 *
 *  @return Yes if the database exist at the database path, NO if not.
 */
- (BOOL)exists;

/**
 *  Does a backup exist
 *
 *  @return Yes if the database exist at the backup path, NO if not.
 */
- (BOOL)backupExists;

/**
 *  Moves old data to backup location
 *
 *  @return YES if succesful, otherwise NO
 */
- (BOOL)moveOldDataToBackupLocation;

/**
 *  Removes old data if it is older than the grace period for backups
 *
 *  @return YES is removed, otherwise NO
 */

- (BOOL)removeOldDataIfOlderThanMaximumGracePeriod;

/**
 *  Removes backups immediately
 *
 *  @return YES is successful, otherwise NO
 */
- (BOOL)removebackupDataImmediately;




/**
 *  Set the context to use for migration
 */
@property (nonatomic, strong) NSManagedObjectContext* context;

/**
 *  This runs asynchronously.
 *  NOTE: You must set the context before calling this method
 *
 *  Use the progress delegate methods to get notifified when the migration completes.
 */
- (void)migrateData;




@end
