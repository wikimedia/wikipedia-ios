//  Created by Monte Hurd on 12/6/13.

#import "QueuesSingleton.h"

@implementation QueuesSingleton

+ (QueuesSingleton *)sharedInstance
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
        self.articleRetrievalQ = [[NSOperationQueue alloc] init];
        self.searchQ = [[NSOperationQueue alloc] init];
        self.thumbnailQ = [[NSOperationQueue alloc] init];
        //[self setupQMonitorLogging];
    }
    return self;
}

-(void)setupQMonitorLogging
{
    // Listen in on the Q's op counts to ensure they go away properly.
    [self.articleRetrievalQ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [self.searchQ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    [self.thumbnailQ addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSLog(@"QUEUE OP COUNTS: Search %lu, Thumb %lu, Article %lu",
                (unsigned long)self.searchQ.operationCount,
                (unsigned long)self.thumbnailQ.operationCount,
                (unsigned long)self.articleRetrievalQ.operationCount
            );
        });
    }
}

@end
