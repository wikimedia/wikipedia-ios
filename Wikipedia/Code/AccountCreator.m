#import "AccountCreator.h"
#import <AFNetworking/AFNetworking.h>
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"

@interface AccountCreator ()

@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;

@property (strong, nonatomic) NSString *realName;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaWord;

@end

@implementation AccountCreator

- (instancetype)initAndCreateAccountForUserName:(NSString *)userName
                                       realName:(NSString *)realName
                                         domain:(NSString *)domain
                                       password:(NSString *)password
                                          email:(NSString *)email
                                      captchaId:(NSString *)captchaId
                                    captchaWord:(NSString *)captchaWord
                                          token:(NSString *)token
                                    withManager:(AFHTTPSessionManager *)manager
                             thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.userName = userName ? userName : @"";
        self.realName = realName ? realName : @"";
        self.domain = domain ? domain : @"";
        self.password = password ? password : @"";
        self.email = email ? email : @"";
        self.captchaId = captchaId ? captchaId : @"";
        self.captchaWord = captchaWord ? captchaWord : @"";
        self.token = token ? token : @"";

        self.fetchFinishedDelegate = delegate;
        [self createAccountWithManager:manager];
    }
    return self;
}

- (void)createAccountWithManager:(AFHTTPSessionManager *)manager {
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

    NSDictionary *params = [self getAuthManagerParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString
        parameters:params
        progress:NULL
        success:^(NSURLSessionDataTask *operation, id responseObject) {
            //NSLog(@"JSON: %@", responseObject);
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            // Fake out an error if non-dictionary response received.
            if (![responseObject isDict]) {
                responseObject = @{ @"error": @{@"info": @"Account creation data not found."} };
            }

            //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseObject);

            // Handle case where response is received, but API reports error.
            NSError *error = nil;
            if (responseObject[@"error"]) {
                NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                error = [NSError errorWithDomain:@"Acct Creation Fetcher"
                                            code:ACCOUNT_CREATION_ERROR_API
                                        userInfo:errorDict];
            }

            if ([responseObject[@"createaccount"][@"status"] isEqualToString:@"FAIL"] && ![responseObject[@"createaccount"][@"message"] isEqualToString:@"Incorrect or missing CAPTCHA."]) {
                NSMutableDictionary *errorDict = [responseObject[@"createaccount"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = responseObject[@"createaccount"][@"message"];
                error = [NSError errorWithDomain:@"Acct Creation Fetcher"
                                            code:ACCOUNT_CREATION_ERROR_API
                                        userInfo:errorDict];
            }

            NSString *result = @"";
            if (!error) {
                if ([responseObject[@"createaccount"][@"status"] isEqualToString:@"FAIL"] && [responseObject[@"createaccount"][@"message"] isEqualToString:@"Incorrect or missing CAPTCHA."]) {
                    NSMutableDictionary *errorDict = @{}.mutableCopy;

                    errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"account-creation-captcha-required", nil);

                    error = [NSError errorWithDomain:@"Account Creation Fetcher"
                                                code:ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA
                                            userInfo:errorDict];
                }
            }

            [self finishWithError:error
                      fetchedData:result];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            [self finishWithError:error
                      fetchedData:nil];
        }];
}

- (NSMutableDictionary *)getAuthManagerParams {
    NSMutableDictionary *params =
        @{
            @"action": @"createaccount",
            @"username": self.userName,
            @"password": self.password,
            @"retype": self.password,
            @"createreturnurl": @"https://www.wikipedia.org",
            @"email": self.email,
            @"format": @"json"
        }.mutableCopy;

    if (self.token && self.token.length > 0) {
        params[@"createtoken"] = self.token;
    }
    if (self.captchaId && self.captchaId.length > 0) {
        params[@"captchaId"] = self.captchaId;
    }
    if (self.captchaWord && self.captchaWord.length > 0) {
        params[@"captchaWord"] = self.captchaWord;
    }

    return params;
}

@end
