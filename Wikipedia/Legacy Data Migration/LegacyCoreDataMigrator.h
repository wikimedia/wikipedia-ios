
#import <Foundation/Foundation.h>


@class LegacyCoreDataMigrator, MWKArticle, MWKTitle, MWKImage;

@protocol LegacyCoreDataDelegate

- (MWKArticle*)oldDataSchema:(LegacyCoreDataMigrator*)schema migrateArticle:(NSDictionary*)articleDict;

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema
         migrateImage:(NSDictionary*)imageDict
           newArticle:(MWKArticle*)newArticle;

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema migrateHistoryEntry:(NSDictionary*)historyDict;

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema migrateSavedEntry:(NSDictionary*)savedDict;

@end

@protocol LegacyCoreDataMigratorProgressDelegate <NSObject>

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema didUpdateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total;

- (void)oldDataSchemaDidFinishMigration:(LegacyCoreDataMigrator*)schema;

- (void)oldDataSchema:(LegacyCoreDataMigrator*)schema didFinishWithError:(NSError*)error;

@end



@interface LegacyCoreDataMigrator : NSObject

@property (weak) id<LegacyCoreDataDelegate> delegate;
@property (weak) id<LegacyCoreDataMigratorProgressDelegate> progressDelegate;

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
