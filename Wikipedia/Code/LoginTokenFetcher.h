//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "FetcherBase.h"

typedef NS_ENUM (NSInteger, LoginTokenErrorType) {
    LOGIN_TOKEN_ERROR_UNKNOWN = 0,
    LOGIN_TOKEN_ERROR_API     = 1
};

@class AFHTTPSessionManager;

@interface LoginTokenFetcher : FetcherBase

@property (strong, nonatomic, readonly) NSString* domain;
@property (strong, nonatomic, readonly) NSString* userName;
@property (strong, nonatomic, readonly) NSString* password;
@property (strong, nonatomic, readonly) NSString* token;

// Kick-off method. Results are reported to "delegate" via the FetchFinishedDelegate protocol method.
- (instancetype)initAndFetchTokenForDomain:(NSString*)domain
                                  userName:(NSString*)userName
                                  password:(NSString*)password
                            useAuthManager:(BOOL)useAuthManager
                               withManager:(AFHTTPSessionManager*)manager
                        thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate;
@end
