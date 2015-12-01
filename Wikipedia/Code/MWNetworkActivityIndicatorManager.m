//  Created by Felix Mo on 2013-01-30.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkActivityIndicatorManager.h"

// Private
@interface MWNetworkActivityIndicatorManager ()

@property (nonatomic, assign) NSInteger count;

@end


static MWNetworkActivityIndicatorManager* sharedManager;


@implementation MWNetworkActivityIndicatorManager

+ (MWNetworkActivityIndicatorManager*)sharedManager {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedManager = [[MWNetworkActivityIndicatorManager alloc] init];
    });

    return sharedManager;
}

- (void)setCount:(NSInteger)count {
    _count = MAX(count, 0);

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_count > 0 ? YES : NO];
}

- (void)push {
    dispatch_async(dispatch_get_main_queue(), ^(){
        @synchronized(self) {
            self.count += 1;
        }
    });
}

- (void)pop {
    dispatch_async(dispatch_get_main_queue(), ^(){
        @synchronized(self) {
            self.count -= 1;
        }
    });
}

@end