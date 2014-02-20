//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

@interface SearchThumbUrlsOp : MWNetworkOp

@property (strong, nonatomic) NSArray *titles;

- (id)initWithCompletionBlock: (void (^)(NSDictionary *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
;

@end
