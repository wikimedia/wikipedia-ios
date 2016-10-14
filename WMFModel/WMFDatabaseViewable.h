#import <YapDatabase/YapDatabase.h>
#import <YapDataBase/YapDatabaseView.h>
#import <YapDataBase/YapDatabaseFilteredView.h>

@protocol WMFDatabaseViewable <NSObject>

/**
 *  Register views for the given model class.
 *  All persistent views for a given class you should register it within this method.
 *  This method should be implemented in a way in which multiple calls are supported (dispatch_once)
 */
+ (void)registerViewsInDatabase:(YapDatabase *)database;

@end
