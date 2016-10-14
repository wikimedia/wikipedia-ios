#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFContentSource <NSObject>

//Start monitoring for content updates
// If you have any pending data to process you shoud do it now.
- (void)startUpdating;

//Stop monitoring for content updates
- (void)stopUpdating;

/**
 *  Update now. If force is YES, you should violate any internal business rules and run your update logic immediately.
 *
 */
- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion;

/**
 * Remove all content from the DB
 */
- (void)removeAllContent;

@optional

/**
 * Load old content into the DB if possible
 */
- (void)preloadContentForNumberOfDays:(NSInteger)days completion:(nullable dispatch_block_t)completion;

/**
 * Load old content into the DB if possible
 */
- (void)loadContentForDate:(NSDate *)date completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
