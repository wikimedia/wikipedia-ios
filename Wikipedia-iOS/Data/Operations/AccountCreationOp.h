//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

typedef enum {
    ACCOUNT_CREATION_ERROR_UNKNOWN = 0,
    ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA = 1
} AccountCreationOpErrors;

@interface AccountCreationOp : MWNetworkOp

@property (strong, nonatomic) NSString *token;

- (id)initWithDomain: (NSString *) domain
            userName: (NSString *) userName
            password: (NSString *) password
            realName: (NSString *) realName
               email: (NSString *) email
           captchaId: (NSString *) captchaId
         captchaWord: (NSString *) captchaWord
     completionBlock: (void (^)(NSString *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
;

@end
