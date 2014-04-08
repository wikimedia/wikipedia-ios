//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

@interface AccountCreationTokenOp : MWNetworkOp

- (id)initWithDomain: (NSString *) domain
            userName: (NSString *) userName
            password: (NSString *) password
     completionBlock: (void (^)(NSString *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
;

@end
