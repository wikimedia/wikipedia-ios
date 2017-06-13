#import <WMF/MWNetworkActivityIndicatorManager.h>

// Private
@interface MWNetworkActivityIndicatorManager ()

@property (nonatomic, assign) NSInteger count;

@end

static MWNetworkActivityIndicatorManager *sharedManager;

@implementation MWNetworkActivityIndicatorManager

+ (MWNetworkActivityIndicatorManager *)sharedManager {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedManager = [[MWNetworkActivityIndicatorManager alloc] init];
    });

    return sharedManager;
}

- (void)setCount:(NSInteger)count {
    _count = MAX(count, 0);
#if WMF_APP_EXTENSION
#else
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_count > 0 ? YES : NO];
#endif
}

- (void)push {
    dispatch_async(dispatch_get_main_queue(), ^() {
        @synchronized(self) {
            self.count += 1;
        }
    });
}

- (void)pop {
    dispatch_async(dispatch_get_main_queue(), ^() {
        @synchronized(self) {
            self.count -= 1;
        }
    });
}

@end
