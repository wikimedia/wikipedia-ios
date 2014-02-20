//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

@interface SearchOp : MWNetworkOp

- (id)initWithSearchTerm: (NSString *)searchTerm
     completionBlock: (void (^)(NSArray *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
;

@end
