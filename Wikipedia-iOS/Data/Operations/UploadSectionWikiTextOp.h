//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

typedef enum {
    WIKITEXT_UPLOAD_ERROR_UNKNOWN = 0,
    WIKITEXT_UPLOAD_ERROR_SERVER = 1,
    WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA = 2,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED = 3,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING = 4,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER = 5
} UploadSectionWikiTextOpErrors;

@interface UploadSectionWikiTextOp : MWNetworkOp

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSNumber *)section
              wikiText: (NSString *)wikiText
               summary: (NSString *)summary
             captchaId: (NSString *)captchaId
           captchaWord: (NSString *)captchaWord
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
