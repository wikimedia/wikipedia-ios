#import <Foundation/Foundation.h>

@class WMFZeroMessage;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const WMFZeroDispositionDidChange;

extern NSString *const ZeroOnDialogShownOnce;
extern NSString *const ZeroWarnWhenLeaving;

@interface ZeroConfigState : NSObject

@property (nonatomic, strong, nullable, readonly) WMFZeroMessage *zeroMessage;

/**
 *  Whether or not the user is on a Wikipedia-Zero-rated network.
 */
@property (atomic, readonly) BOOL disposition;

/**
 *  Whether or not the user prefers to see a modal alert before going to a non-zero-rated URL (i.e. off of Wikipedia).
 */
@property (nonatomic) BOOL warnWhenLeaving;

/**
 * Inspects response headers to determine if network is Zero rated. Sets "disposition" to YES if so or NO if not.
 * Posts WMFZeroDispositionDidChange notification if change is made to "disposition".
 */
- (void)inspectResponseForZeroHeaders:(NSURLResponse*)response;

@end

NS_ASSUME_NONNULL_END
