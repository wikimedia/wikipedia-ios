//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

typedef enum {
    WIKITEXT_UPLOAD_ERROR_SERVER = 0,
    WIKITEXT_UPLOAD_ERROR_UNKNOWN = 1,
    WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA = 2
} UploadSectionWikiTextOpErrors;

@interface UploadSectionWikiTextOp : MWNetworkOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSNumber *)section
              wikiText: (NSString *)wikiText
              captchaId: (NSString *)captchaId
              captchaWord: (NSString *)captchaWord
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
