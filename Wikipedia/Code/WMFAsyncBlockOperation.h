#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WMFAsyncBlockOperation;

typedef void (^ WMFAsyncBlock)(WMFAsyncBlockOperation* operation);

@interface WMFAsyncBlockOperation : NSOperation

- (nonnull instancetype)initWithBlock:(WMFAsyncBlock)block;

/**
 *  Blocks must invoke the finish method when work is complete
 *  Otherwise the Queue will lock
 */
- (void)finish;

@end


@interface NSOperationQueue (AsyncBlockOperation)

- (void)wmf_addOperationWithAsyncBlock:(WMFAsyncBlock)block;

@end

NS_ASSUME_NONNULL_END