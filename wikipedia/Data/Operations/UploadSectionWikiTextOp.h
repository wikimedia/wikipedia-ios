//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

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

// Note: "section" parameter needs to be a string because the
// api returns transcluded section indexes with a "T-" prefix

- (id)initForPageTitle: (NSString *)title
                domain: (NSString *)domain
               section: (NSString *)section
              wikiText: (NSString *)wikiText
               summary: (NSString *)summary
             captchaId: (NSString *)captchaId
           captchaWord: (NSString *)captchaWord
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
