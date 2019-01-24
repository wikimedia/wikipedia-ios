@import Foundation;

#ifndef Wikipedia_WMFGCDHelpers_h
#define Wikipedia_WMFGCDHelpers_h

#pragma mark - Dispatch Time

static inline double nanosecondsWithSeconds(NSTimeInterval seconds) {
    return (seconds * 1000000000);
}

static inline dispatch_time_t dispatchTimeFromNowWithDelta(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)nanosecondsWithSeconds(seconds));
}

#pragma mark - Dispatch After

static inline void dispatchAfterDelayInSeconds(NSTimeInterval delay, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_after(dispatchTimeFromNowWithDelta(delay), queue, block);
}

static inline void dispatchOnMainQueueAfterDelayInSeconds(NSTimeInterval delay, dispatch_block_t block) {
    dispatchAfterDelayInSeconds(delay, dispatch_get_main_queue(), block);
}

#endif
