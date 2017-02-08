#import "WMFAuthenticationManager.h"
#import "KeychainCredentials.h"
#import "AFHTTPSessionManager+WMFCancelAll.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"
#import "NSHTTPCookieStorage+WMFCloneCookie.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthenticationManager ()

@property (strong, nonatomic) KeychainCredentials *keychainCredentials;

@property (strong, nonatomic, nullable) WMFAuthLoginInfoFetcher* authLoginInfoFetcher;
@property (strong, nonatomic, nullable) WMFAuthAccountCreationInfoFetcher* authAccountCreationInfoFetcher;
@property (strong, nonatomic, nullable) WMFAuthAccountCreationInfo *authAccountCreationInfo;

@property (strong, nonatomic, readwrite, nullable) NSString *loggedInUsername;

@property (strong, nonatomic, nullable) NSString *authenticatingUsername;
@property (strong, nonatomic, nullable) NSString *authenticatingPassword;
@property (strong, nonatomic, nullable) NSString *authenticatingRetypePassword;
@property (strong, nonatomic, nullable) NSString *email;
@property (strong, nonatomic, nullable) NSString *captchaText;

@property (strong, nonatomic, nullable) WMFAuthTokenFetcher *loginTokenFetcher;
@property (strong, nonatomic, nullable) WMFAccountLogin *accountLogin;
@property (strong, nonatomic, nullable) NSString *oathToken;

@property (strong, nonatomic, nullable) NSString *accountCreationToken;
@property (strong, nonatomic, nullable) WMFAuthTokenFetcher *accountCreationTokenFetcher;
@property (strong, nonatomic, nullable) WMFAccountCreator *accountCreator;

@property (nonatomic, copy, nullable) dispatch_block_t successBlock;
@property (nonatomic, copy, nullable) WMFCaptchaHandler captchaBlock;
@property (nonatomic, copy, nullable) WMFErrorHandler failBlock;

@property (strong, nonatomic, nullable) WMFCurrentlyLoggedInUserFetcher *currentlyLoggedInUserFetcher;

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
        self.keychainCredentials = [[KeychainCredentials alloc] init];
    }
    return self;
}

#pragma mark - Account Creation

- (void)getAccountCreationCaptchaWithUsername:(NSString *)username password:(NSString *)password email:(nullable NSString *)email captcha:(WMFCaptchaHandler)captcha failure:(WMFErrorHandler)failure {
    if (self.successBlock || self.failBlock) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeFetchAlreadyInProgress userInfo:nil]);
        }
        return;
    }

    self.authenticatingUsername = username;
    self.authenticatingPassword = password;
    self.email = email;

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
    self.failBlock = failure;
    self.successBlock = nil;

    self.authAccountCreationInfoFetcher = [[WMFAuthAccountCreationInfoFetcher alloc] init];
    @weakify(self)
    [self.authAccountCreationInfoFetcher fetchAccountCreationInfoForSiteURL:[[MWKLanguageLinkController sharedInstance] appLanguage].siteURL
                                                                 success:^(WMFAuthAccountCreationInfo* info){
                                                                     @strongify(self)

                                                                     self.authAccountCreationInfo = info;
                                                                     
                                                                     NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
                                                                     self.accountCreationTokenFetcher = [[WMFAuthTokenFetcher alloc] init];
                                                                     [self.accountCreationTokenFetcher fetchTokenOfType:WMFAuthTokenTypeCreateAccount siteURL:siteURL success:^(WMFAuthToken* result){
                                                                         @strongify(self)
                                                                         self.accountCreationToken = result.token;
                                                                         //Need to attempt account create to verify username and password
                                                                         [self createAccountWithCaptchaID:nil];
                                                                     } failure:^(NSError* error){
                                                                         [self finishAndSendFailureBlockWithError:error];
                                                                     }];
                                                                     
                                                                 }
                                                                    failure:^(NSError *error) {
                                                                        [self finishAndSendFailureBlockWithError:error];
                                                                    }];
}

- (void)createAccountWithCaptchaText:(NSString *)captchaText success:(dispatch_block_t)success captcha:(WMFCaptchaHandler)captcha failure:(WMFErrorHandler)failure {
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

    self.captchaText = captchaText;
    self.successBlock = success;
    self.captchaBlock = captcha;
    self.failBlock = failure;

    [self createAccountWithCaptchaID:self.authAccountCreationInfo.captchaID];
}

- (void)createAccountWithCaptchaID:(nullable NSString *)captchaID {
    
    NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];

    self.accountCreator = [[WMFAccountCreator alloc] init];
    
    @weakify(self)
    [self.accountCreator createAccountWithUsername:self.authenticatingUsername
                                          password:self.authenticatingPassword
                                    retypePassword:self.authenticatingPassword
                                             email:self.email
                                         captchaID:captchaID
                                       captchaWord:self.captchaText
                                             token:self.accountCreationToken
                                           siteURL:siteURL
                                        success:^(WMFAccountCreatorResult* result){
                                            @strongify(self)
                                            
                                            [self loginWithSuccess:self.successBlock failure:self.failBlock];
                                            
                                        } failure:^(NSError* error){
                                            
                                            if (error.code == WMFAccountCreatorErrorTypeNeedsCaptcha) {
                                                
                                                if ([self isInitialAccountCreationAttempt]) {
                                                    //First time attempting to create an account with this captcha URL.
                                                    //By design, no captcha text was sent
                                                    //This is because we want to get any errors back from the API about duplicate user names before we present the captcha
                                                    //In this case, the user name is fine and we can fire the block and have them solve the captcha
                                                    [self sendCaptchaBlockWithURLFragment:self.authAccountCreationInfo.captchaURLFragment];
                                                } else {
                                                    //The user tried to solve the captch and failed
                                                    //Get another captcha URL and have the user try again
                                                    [self getAccountCreationCaptchaWithHandler:self.captchaBlock failure:self.failBlock];
                                                }
                                            } else {
                                                [self finishAndSendFailureBlockWithError:error];
                                            }
                                            
                                        }];
}

#pragma mark - Login

- (BOOL)isLoggedIn {
    return self.loggedInUsername != nil;
}

- (void)loginWithSavedCredentialsWithSuccess:(nullable dispatch_block_t)success
                      userWasAlreadyLoggedIn:(nullable void (^)(WMFCurrentlyLoggedInUser *))loggedInUserHandler
                                     failure:(nullable WMFErrorHandler)failure {
    
    NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
    
    self.currentlyLoggedInUserFetcher = [[WMFCurrentlyLoggedInUserFetcher alloc] init];
    @weakify(self);
    [self.currentlyLoggedInUserFetcher fetchWithSiteURL:siteURL
                                             success:^(WMFCurrentlyLoggedInUser * _Nonnull currentlyLoggedInUser) {
                                                 @strongify(self);
                                                 
                                                 self.loggedInUsername = currentlyLoggedInUser.name;
                                                 
                                                 if(loggedInUserHandler){
                                                     loggedInUserHandler(currentlyLoggedInUser);
                                                 }
                                                 
                                             } failure:^(NSError * _Nonnull error) {
                                                 @strongify(self);
                                                 
                                                 self.loggedInUsername = nil;
                                                 
                                                 [self loginWithUsername:self.keychainCredentials.userName
                                                                password:self.keychainCredentials.password
                                                          retypePassword:nil
                                                               oathToken:nil
                                                                 success:success
                                                                 failure:^(NSError *error) {
                                                                     @strongify(self);
                                                                     
                                                                     if(error.code != kCFURLErrorNotConnectedToInternet){
                                                                         [self logout];
                                                                     }
                                                                     
                                                                     if (failure) {
                                                                         failure(error);
                                                                     }
                                                                 }];
                                             }];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password retypePassword:(nullable NSString*)retypePassword oathToken:(nullable NSString*)oathToken success:(nullable dispatch_block_t)success failure:(nullable WMFErrorHandler)failure {
    if (self.successBlock || self.failBlock) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeFetchAlreadyInProgress userInfo:nil]);
        }
        return;
    }

    self.authenticatingUsername = username;
    self.authenticatingPassword = password;
    self.authenticatingRetypePassword = retypePassword;
    self.oathToken = oathToken;

    [self loginWithSuccess:success failure:failure];
}

- (void)loginWithSuccess:(nullable dispatch_block_t)success failure:(nullable WMFErrorHandler)failure {
    if (self.authenticatingUsername.length == 0 || self.authenticatingPassword.length == 0) {
        if (failure) {
            failure([NSError wmf_errorWithType:WMFErrorTypeStringMissingParameter userInfo:nil]);
        }
        return;
    }

    self.authLoginInfoFetcher = [[WMFAuthLoginInfoFetcher alloc] init];
    @weakify(self)
    [self.authLoginInfoFetcher fetchLoginInfoForSiteURL:[[MWKLanguageLinkController sharedInstance] appLanguage].siteURL
                                             success:^(WMFAuthLoginInfo* info){
                                                 @strongify(self)
                                                 
                                                 NSURL *siteURL = [[SessionSingleton sharedInstance] urlForLanguage:[[MWKLanguageLinkController sharedInstance] appLanguage].languageCode];
                                                 
                                                 self.loginTokenFetcher = [[WMFAuthTokenFetcher alloc] init];
                                                 [self.loginTokenFetcher fetchTokenOfType:WMFAuthTokenTypeLogin siteURL:siteURL success:^(WMFAuthToken* result){
                                                     
                                                     @strongify(self)
                                                     self.accountLogin = [[WMFAccountLogin alloc] init];
                                                     [self.accountLogin loginWithUsername:self.authenticatingUsername
                                                                                 password:self.authenticatingPassword
                                                                           retypePassword:self.authenticatingRetypePassword
                                                                               loginToken:result.token
                                                                                oathToken:self.oathToken
                                                                                  siteURL:siteURL
                                                                                  success:^(WMFAccountLoginResult* result){
                                                                                      @strongify(self)
                                                                                      NSString *normalizedUserName = result.username;
                                                                                      self.loggedInUsername = normalizedUserName;
                                                                                      self.keychainCredentials.userName = normalizedUserName;
                                                                                      self.keychainCredentials.password = self.authenticatingPassword;
                                                                                      self.authenticatingPassword = nil;
                                                                                      self.authenticatingRetypePassword = nil;
                                                                                      self.authenticatingUsername = nil;
                                                                                      [self cloneSessionCookies];
                                                                                      if (success){
                                                                                          success();
                                                                                      }
                                                                                  } failure:failure];
                                                 } failure:failure];
                                                 
                                             } failure:failure];
}

- (BOOL)isInitialAccountCreationAttempt {
    return self.successBlock == nil;
}

#pragma mark - Logout

- (void)logout {
    self.keychainCredentials.userName = nil;
    self.keychainCredentials.password = nil;
    self.loggedInUsername = nil;
    self.email = nil;
    self.oathToken = nil;
    // Clear session cookies too.
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

#pragma mark - Cookie Sync

- (void)cloneSessionCookies {
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString *domain = [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode;

    NSString *cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString *cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:cookie1Name
                                                usingCookieAsTemplate:cookie2Name];

    [[NSHTTPCookieStorage sharedHTTPCookieStorage] wmf_recreateCookie:@"centralauth_Session"
                                                usingCookieAsTemplate:@"centralauth_User"];
}

#pragma mark - Send completion blocks

- (void)sendCaptchaBlockWithURLFragment:(NSString *)captchaURLFragment {
    if (self.captchaBlock) {
        NSURL *captchaImageUrl = [NSURL URLWithString:
                                            [NSString stringWithFormat:@"https://%@.m.%@%@", [[MWKLanguageLinkController sharedInstance] appLanguage].languageCode,
                                                                       [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL].wmf_domain,
                                                                       captchaURLFragment]];
        self.captchaBlock(captchaImageUrl);
    }
    self.failBlock = nil;
    self.captchaBlock = nil;
    self.successBlock = nil;
}

- (void)finishAndSendFailureBlockWithError:(NSError *)error {
    if (self.failBlock) {
        self.failBlock(error);
    }
    self.failBlock = nil;
    self.captchaBlock = nil;
    self.successBlock = nil;
}

@end

NS_ASSUME_NONNULL_END
