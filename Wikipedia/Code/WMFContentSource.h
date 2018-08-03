@import CoreData;

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
 * Load content for a specific date into the DB
 */
- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion;

@end

@protocol WMFOptionalNewContentSource <NSObject>

/**
 * Load content for a specific date into the DB
 */
- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
