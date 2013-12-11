//  Created by Monte Hurd on 12/6/13.

#import "SessionSingleton.h"

@implementation SessionSingleton

+ (SessionSingleton *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self dataSetup];
    }
    return self;
}

-(void)dataSetup
{
    // Make site available
    self.site = @"wikipedia.org";

    // Make domain available
    self.domain = @"en";
}

@end
