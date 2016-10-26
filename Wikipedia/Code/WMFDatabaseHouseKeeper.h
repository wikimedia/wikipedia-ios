
#import <Foundation/Foundation.h>

@interface WMFDatabaseHouseKeeper : NSObject

- (void)performHouseKeepingWithCompletion:(dispatch_block_t)completion;

@end
