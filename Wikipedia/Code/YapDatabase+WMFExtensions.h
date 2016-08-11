
#import <YapDatabase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>

@interface YapDatabase (WMFExtensions)

/**
 *  The default database path
 *
 *  @return A path
 */
+ (NSString*)wmf_databasePath;

- (YapDatabaseConnection*)wmf_newReadConnection;

- (YapDatabaseConnection*)wmf_newLongLivedReadConnection;

- (YapDatabaseConnection*)wmf_newWriteConnection;

/**
 *  Convienence method for registerExtension:withName:
 *
 *  @param view The view to register
 *  @param name The neame of the view
 */
- (void)wmf_registerView:(YapDatabaseView*)view withName:(NSString*)name;

@end
