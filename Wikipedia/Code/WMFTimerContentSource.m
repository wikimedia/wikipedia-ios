#import "WMFTimerContentSource.h"

@interface WMFTimerContentSource ()

@property (readwrite, nonatomic, strong) NSTimer *updateTimer;

@end

@implementation WMFTimerContentSource

- (instancetype)init {
    self = [super init];
    if (self) {
        self.updateInterval = 60 * 30;
    }
    return self;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
    [self stopUpdating];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval target:self selector:@selector(updateWithTimer:) userInfo:nil repeats:YES];
    [self loadNewContentForce:NO completion:NULL];
}

- (void)stopUpdating {
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    //nonop - implemented by subclasses
}

#pragma mark - Timer Trigger

- (void)updateWithTimer:(NSTimer *)timer {
    [self loadNewContentForce:NO completion:NULL];
}

@end
