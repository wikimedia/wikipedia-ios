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
   BOOL shouldBeVisible = _count > 0;
   UIApplication *app = [UIApplication sharedApplication];
   if (shouldBeVisible != app.isNetworkActivityIndicatorVisible) {
      dispatch_async(dispatch_get_main_queue(), ^{
         [app setNetworkActivityIndicatorVisible:shouldBeVisible];
      });
   }
#endif
}

- (void)push {
   @synchronized(self) {
      self.count += 1;
   }
}

- (void)pop {
   @synchronized(self) {
      self.count += 1;
   }
}

@end
