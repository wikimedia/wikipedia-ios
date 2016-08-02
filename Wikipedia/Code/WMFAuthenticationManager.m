
#import "WMFAuthenticationManager.h"
#import "WMFAuthManagerInfoFetcher.h"
#import "WMFAuthManagerInfo.h"

#import "KeychainCredentials.h"

#import "QueuesSingleton.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"

#import "LoginTokenFetcher.h"
#import "AccountLogin.h"

#import "AccountCreationTokenFetcher.h"
#import "AccountCreator.h"

#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"

#import "NSHTTPCookieStorage+WMFCloneCookie.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthenticationManager ()<FetchFinishedDelegate>

@property (strong, nonatomic) KeychainCredentials* keychainCredentials;

@property (strong, nonatomic, nullable) WMFAuthManagerInfoFetcher* authManagerInfoFetcher;
@property (strong, nonatomic, nullable) WMFAuthManagerInfo* loginAuthManagerInfo;
@property (strong, nonatomic, nullable) WMFAuthManagerInfo* accountCreationAuthManagerInfo;

@property (strong, nonatomic, readwrite, nullable) NSString* loggedInUsername;

@property (strong, nonatomic, nullable) NSString* authenticatingUsername;
@property (strong, nonatomic, nullable) NSString* authenticatingPassword;
@property (strong, nonatomic, nullable) NSString* email;
@property (strong, nonatomic, nullable) NSString* captchaText;

@property (strong, nonatomic, nullable) NSString* loginToken;
@property (strong, nonatomic, nullable) NSString* accountCreationToken;

@property (nonatomic, copy, nullable) dispatch_block_t successBlock;
@property (nonatomic, copy, nullable) WMFCaptchaHandler captchaBlock;
@property (nonatomic, copy, nullable) WMFErrorHandler failBlock;

@end

@implementation WMFAuthenticationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keychainCredentials    = [[KeychainCredentials alloc] init];
        self.authManagerInfoFetcher = [[WMFAuthManagerInfoFetcher alloc] init];
    }
    return self;
}

#pragma mark - Account Creation

- (void)getAccountCreationCaptchaWithUsername:(NSString*)username password:(NSString*)password email:(nullable NSString*)email captcha:(WMFCaptchaHandler)captcha failure:(WMFErrorHandler)failure {
    if (self.successBlock || self.failBlock) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeFetchAlreadyInProgress userInfo:nil]);
        }
        return;
    }

    self.authenticatingUsername = username;
    self.authenticatingPassword = password;
    self.email                  = email;

    [self getAccountCreationCaptchaWithHandler:captcha failure:failure];
}

- (void)getAccountCreationCaptchaWithHandler:(WMFCaptchaHandler)captcha failure:(WMFErrorHandler)failure {
    if (self.authenticatingUsername.length == 0 || self.authenticatingPassword.length == 0 || captcha == nil || failure == nil) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
        return;
    }

    self.captchaBlock = captcha;
    self.failBlock    = failure;
    self.successBlock = nil;

    [self fetchCreationAuthManagerInfoWithSuccess:^(WMFAuthManagerInfo* _Nonnull info) {
        self.accountCreationAuthManagerInfo = info;
        [self fetchCreationTokensWithInfo:info username:self.authenticatingUsername password:self.authenticatingPassword email:self.email];
    } failure:^(NSError* error) {
        [self finishAndSendFailureBlockWithError:error];
    }];
}

- (void)fetchCreationAuthManagerInfoWithSuccess:(nullable WMFAuthManagerInfoBlock)success failure:(nullable WMFErrorHandler)failure {
    [self.authManagerInfoFetcher fetchAuthManagerCreationAvailableForSiteURL:[[MWKLanguageLinkController sharedInstance] appLanguage].siteURL success:^(WMFAuthManagerInfo* _Nonnull info) {
        success(info);
    } failure:^(NSError* error) {
        failure(error);
    }];
}

- (void)fetchCreationTokensWithInfo:(WMFAuthManagerInfo*)info username:(NSString*)username password:(NSString*)password email:(nullable NSString*)email {
    [[QueuesSingleton sharedInstance].accountCreationFetchManager wmf_cancelAllTasksWithCompletionHandler:^{
        (void)[[AccountCreationTokenFetcher alloc] initAndFetchTokenForDomain:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode
                                                                     userName:username
                                                                     password:password email:email withManager:[QueuesSingleton sharedInstance].accountCreationFetchManager
                                                           thenNotifyDelegate:self];
    }];
}

- (void)createAccountWithCaptchaText:(NSString*)captchaText success:(dispatch_block_t)success captcha:(WMFCaptchaHandler)captcha failure:(WMFErrorHandler)failure {
    if (self.authenticatingUsername.length == 0 || self.authenticatingPassword.length == 0 || success == nil || captcha == nil || failure == nil) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
        return;
    }

    if (self.successBlock || self.failBlock) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeFetchAlreadyInProgress userInfo:nil]);
        }
        return;
    }

    self.captchaText  = captchaText;
    self.successBlock = success;
    self.captchaBlock = captcha;
    self.failBlock    = failure;

    [self createAccountWithCaptchaID:self.accountCreationAuthManagerInfo.captchaID];
}

- (void)createAccountWithCaptchaID:(nullable NSString*)captchaID {
    (void)[[AccountCreator alloc] initAndCreateAccountForUserName:self.authenticatingUsername
                                                         realName:@""
                                                           domain:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode
                                                         password:self.authenticatingPassword
                                                            email:self.email
                                                        captchaId:captchaID
                                                      captchaWord:self.captchaText
                                                            token:self.accountCreationToken withManager:[QueuesSingleton sharedInstance].accountCreationFetchManager
                                               thenNotifyDelegate:self];
}

#pragma mark - Login

- (BOOL)isLoggedIn {
    return self.loggedInUsername != nil;
}

- (void)loginWithSavedCredentialsWithSuccess:(nullable dispatch_block_t)success failure:(nullable WMFErrorHandler)failure {
    [self loginWithUsername:self.keychainCredentials.userName password:self.keychainCredentials.password success:success failure:^(NSError* error) {
        if (error.domain == WMFAccountLoginErrorDomain && error.code != LOGIN_ERROR_UNKNOWN && error.code != LOGIN_ERROR_API) {
            [self logout];
        }
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password success:(nullable dispatch_block_t)success failure:(nullable WMFErrorHandler)failure {
    if (self.successBlock || self.failBlock) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeFetchAlreadyInProgress userInfo:nil]);
        }
        return;
    }

    self.authenticatingUsername = username;
    self.authenticatingPassword = password;

    [self loginWithSuccess:success failure:failure];
}

- (void)loginWithSuccess:(nullable dispatch_block_t)success failure:(nullable WMFErrorHandler)failure {
    if (self.authenticatingUsername.length == 0 || self.authenticatingPassword.length == 0) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
        return;
    }

    self.successBlock = success;
    self.failBlock    = failure;

    [self fetchLoginAuthManagerInfoWithSuccess:^(WMFAuthManagerInfo* _Nonnull info) {
        self.loginAuthManagerInfo = info;
        [self fetchLoginTokensWithInfo:info username:self.authenticatingUsername password:self.authenticatingPassword];
    } failure:^(NSError* error) {
        [self finishAndSendFailureBlockWithError:error];
    }];
}

- (void)fetchLoginAuthManagerInfoWithSuccess:(nullable WMFAuthManagerInfoBlock)success failure:(nullable WMFErrorHandler)failure {
    [self.authManagerInfoFetcher fetchAuthManagerLoginAvailableForSiteURL:[[MWKLanguageLinkController sharedInstance] appLanguage].siteURL success:^(WMFAuthManagerInfo* _Nonnull info) {
        success(info);
    } failure:^(NSError* error) {
        failure(error);
    }];
}

- (void)fetchLoginTokensWithInfo:(WMFAuthManagerInfo*)info username:(NSString*)username password:(NSString*)password {
    [[QueuesSingleton sharedInstance].loginFetchManager wmf_cancelAllTasksWithCompletionHandler:^{
        (void)[[LoginTokenFetcher alloc] initAndFetchTokenForDomain:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode
                                                           userName:username
                                                           password:password withManager:[QueuesSingleton sharedInstance].loginFetchManager
                                                 thenNotifyDelegate:self];
    }];
}

- (void)login {
    (void)[[AccountLogin alloc] initAndLoginForDomain:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode
                                             userName:self.authenticatingUsername
                                             password:self.authenticatingPassword
                                                token:self.loginToken
                                          withManager:[QueuesSingleton sharedInstance].loginFetchManager
                                   thenNotifyDelegate:self];
}

#pragma mark - FetchDelegate

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[LoginTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                self.loginToken = [sender token];
                [self login];
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
            case FETCH_FINAL_STATUS_FAILED:
                [self finishAndSendFailureBlockWithError:error];
                break;
        }
    }

    if ([sender isKindOfClass:[AccountLogin class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED: {
                NSString* normalizedUserName = fetchedData[@"username"];
                self.loggedInUsername             = normalizedUserName;
                self.keychainCredentials.userName = normalizedUserName;
                self.keychainCredentials.password = self.authenticatingPassword;
                self.authenticatingPassword       = nil;
                self.authenticatingUsername       = nil;
                [self cloneSessionCookies];
                [self finishAndSendSuccessBlock];
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
            case FETCH_FINAL_STATUS_FAILED:
                [self finishAndSendFailureBlockWithError:error];
                break;
        }
    }
    if ([sender isKindOfClass:[AccountCreationTokenFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
                self.accountCreationToken = [sender token];
                //Need to attempt account create to verify username and password
                [self createAccountWithCaptchaID:nil];
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            case FETCH_FINAL_STATUS_FAILED:
                [self finishAndSendFailureBlockWithError:error];
                break;
        }
    }

    if ([sender isKindOfClass:[AccountCreator class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
                [self loginWithSuccess:self.successBlock failure:self.failBlock];
                break;
            case FETCH_FINAL_STATUS_CANCELLED:
            case FETCH_FINAL_STATUS_FAILED:
                if (error.code == ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA) {
                    if ([self isInitialAccountCreationAtempt]) {
                        //First time attempting to create an account with this captcha URL.
                        //By design, no captcha text was sent
                        //This is because we want to get any errors back from the API about duplicate user names before we present the captcha
                        //In this case, the user name is fine and we can fire the block and have them solve the captcha
                        [self sendCaptchaBlockWithURLString:self.accountCreationAuthManagerInfo.captchaURLFragment];
                    } else {
                        //The user tried to solve the captch and failed
                        //Get another captcha URL and have the user try again
                        [self getAccountCreationCaptchaWithHandler:self.captchaBlock failure:self.failBlock];
                    }
                } else {
                    [self finishAndSendFailureBlockWithError:error];
                }
                break;
        }
    }
}

- (BOOL)isInitialAccountCreationAtempt {
    return self.successBlock == nil;
}

#pragma mark - Logout

- (void)logout {
    self.keychainCredentials.userName   = nil;
    self.keychainCredentials.password   = nil;
    self.keychainCredentials.editTokens = nil;
    self.loggedInUsername               = nil;
    self.email                          = nil;
    self.loginToken                     = nil;
    // Clear session cookies too.
    for (NSHTTPCookie* cookie in[[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark - Cookie Sync

- (void)cloneSessionCookies {
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString* domain = [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode;

    NSString* cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString* cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:cookie1Name
                                                usingCookieAsTemplate:cookie2Name
    ];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:@"centralauth_Session"
                                                usingCookieAsTemplate:@"centralauth_User"
    ];
}

#pragma mark - Send completion blocks

- (void)sendCaptchaBlockWithURLString:(NSString*)captchaURLString {
    if (self.captchaBlock) {
        NSURL* captchaImageUrl = [NSURL URLWithString:
                                  [NSString stringWithFormat:@"https://%@.m.%@%@", [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode,
                                   [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL].wmf_domain,
                                   captchaURLString
                                  ]
                                 ];
        self.captchaBlock(captchaImageUrl);
    }
    self.failBlock    = nil;
    self.captchaBlock = nil;
    self.successBlock = nil;
}

- (void)finishAndSendFailureBlockWithError:(NSError*)error {
    if (self.failBlock) {
        self.failBlock(error);
    }
    self.failBlock    = nil;
    self.captchaBlock = nil;
    self.successBlock = nil;
}

- (void)finishAndSendSuccessBlock {
    if (self.successBlock) {
        self.successBlock();
    }
    self.failBlock    = nil;
    self.captchaBlock = nil;
    self.successBlock = nil;
}

@end


NS_ASSUME_NONNULL_END