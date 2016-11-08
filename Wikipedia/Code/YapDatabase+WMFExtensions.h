#import <YapDatabase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>

@interface YapDatabase (WMFExtensions)

/**
 *  Returns the shared DB for the app using the path below.
 *  This also registers all views by calling wmf_registerViews (See YapDatabase+WMFViews.h)
 */
+ (instancetype)sharedInstance;

+ (instancetype)wmf_databaseWithDefaultConfiguration;

+ (instancetype)wmf_databaseWithDefaultConfigurationAtPath:(NSString *)path;

+ (void)wmf_registerViewsInDatabase:(YapDatabase *)db;

/**
 *  The default database path. 
 *  This is used for the sharedInstance
 *
 *  @return A path
 */
+ (NSString *)wmf_databasePath;

+ (NSString *)wmf_appSpecificDatabasePath;

- (YapDatabaseConnection *)wmf_newReadConnection;

- (YapDatabaseConnection *)wmf_newLongLivedReadConnection;

- (YapDatabaseConnection *)wmf_newWriteConnection;

/**
 *  Convienence method for registerExtension:withName:
 *
 *  @param view The view to register
 *  @param name The neame of the view
 */
- (void)wmf_registerView:(YapDatabaseView *)view withName:(NSString *)name;

@end
