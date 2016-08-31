
#import "WMFFeedSource.h"

@interface WMFTimerFeedSource : NSObject<WMFFeedSource>

@property (nonatomic, assign) NSTimeInterval updateInterval; //Default is 30 minutes

@end


@interface WMFTimerFeedSource (WMFSubclasses)

@property (readonly, nonatomic, strong) NSTimer* updateTimer;

@end


