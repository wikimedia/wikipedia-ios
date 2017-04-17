#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFContentSource <NSObject>

/**
 *  Update now. If force is YES, you should violate any internal business rules and run your update logic immediately.
 *
 */
- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion;

/**
 * Remove all content from the DB
 */
- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc;

@end

@protocol WMFAutoUpdatingContentSource <NSObject>

//Start monitoring for content updates
- (void)startUpdating;

//Stop monitoring for content updates
- (void)stopUpdating;

@end

@protocol WMFDateBasedContentSource <NSObject>

/**
 * Load old content into the DB if possible
 */
- (void)preloadContentForNumberOfDays:(NSInteger)days inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion;

/**
 * Load content for a specific date into the DB
 */
- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
