//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM(NSInteger, EditTokenErrorType) {
    EDIT_TOKEN_ERROR_UNKNOWN = 0,
    EDIT_TOKEN_ERROR_API = 1
};

@class AFHTTPRequestOperationManager;

@interface EditTokenFetcher : FetcherBase

@property (strong, nonatomic, readonly) NSString *wikiText;
@property (strong, nonatomic, readonly) MWKTitle *title;
@property (strong, nonatomic, readonly) NSString *section;
@property (strong, nonatomic, readonly) NSString *summary;
@property (strong, nonatomic, readonly) NSString *captchaId;
@property (strong, nonatomic, readonly) NSString *captchaWord;
@property (strong, nonatomic, readonly) NSString *token;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.

// Only the domain is used to actually fetch the token, the other values are
// parked here so the actual uploader can have quick read-only access to the
// exact params which kicked off the token request.
-(instancetype)initAndFetchEditTokenForWikiText: (NSString *)wikiText
                                      pageTitle: (MWKTitle *)title
                                        section: (NSString *)section
                                        summary: (NSString *)summary
                                      captchaId: (NSString *)captchaId
                                    captchaWord: (NSString *)captchaWord
                                    withManager: (AFHTTPRequestOperationManager *)manager
                             thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate;

@end
