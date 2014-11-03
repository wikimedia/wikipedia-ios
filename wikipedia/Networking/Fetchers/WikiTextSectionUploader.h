//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, WikiTextSectionUploaderErrors) {
    WIKITEXT_UPLOAD_ERROR_UNKNOWN = 0,
    WIKITEXT_UPLOAD_ERROR_SERVER = 1,
    WIKITEXT_UPLOAD_ERROR_NEEDS_CAPTCHA = 2,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_DISALLOWED = 3,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_WARNING = 4,
    WIKITEXT_UPLOAD_ERROR_ABUSEFILTER_OTHER = 5
};

@class AFHTTPRequestOperationManager;

@interface WikiTextSectionUploader : FetcherBase

@property (strong, nonatomic, readonly) NSString *wikiText;
@property (strong, nonatomic, readonly) MWKTitle *title;
@property (strong, nonatomic, readonly) NSString *section;
@property (strong, nonatomic, readonly) NSString *summary;
@property (strong, nonatomic, readonly) NSString *captchaId;
@property (strong, nonatomic, readonly) NSString *captchaWord;
@property (strong, nonatomic, readonly) NSString *token;

// Kick-off method. Results are reported to "delegate" via the
// FetchFinishedDelegate protocol method.

// Note: "section" parameter needs to be a string because the
// api returns transcluded section indexes with a "T-" prefix
-(instancetype)initAndUploadWikiText: (NSString *)wikiText
                        forPageTitle: (MWKTitle *)title
                             section: (NSString *)section
                             summary: (NSString *)summary
                           captchaId: (NSString *)captchaId
                         captchaWord: (NSString *)captchaWord
                               token: (NSString *)token
                         withManager: (AFHTTPRequestOperationManager *)manager
                  thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;
@end
