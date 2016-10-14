@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFTimerContentSource : NSObject

@property (nonatomic, assign) NSTimeInterval updateInterval; //Default is 30 minutes

- (void)startUpdating;
- (void)stopUpdating;

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
