
#import "WMFTimerFeedSource.h"

@interface WMFTimerFeedSource ()

@property (readwrite, nonatomic, strong) NSTimer* updateTimer;

@end

@implementation WMFTimerFeedSource

- (instancetype)init{
    self = [super init];
    if (self) {
        self.updateInterval = 60*30;
    }
    return self;
}

#pragma mark - WMFFeedSource

- (void)startUpdating{
    [self stopUpdating];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval target:self selector:@selector(updateWithTimer:) userInfo:nil repeats:YES];
}

- (void)stopUpdating{
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)updateForce:(BOOL)force{
    //nonop - implemented by subclasses
}


#pragma mark - Timer Trigger

- (void)updateWithTimer:(NSTimer*)timer{
    [self updateForce:NO];
}

@end
