#import "AccountLogin.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"

NSString *const WMFAccountLoginErrorDomain = @"WMFAccountLoginErrorDomain";

@interface AccountLogin ()

@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *token;

@end

@implementation AccountLogin

- (instancetype)initAndLoginForDomain:(NSString *)domain
                             userName:(NSString *)userName
                             password:(NSString *)password
                                token:(NSString *)token
                          withManager:(AFHTTPSessionManager *)manager
                   thenNotifyDelegate:(id<FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.domain = domain ? domain : @"";
        self.userName = userName ? userName : @"";
        self.password = password ? password : @"";
        self.token = token ? token : @"";

        self.fetchFinishedDelegate = delegate;
        [self loginWithManager:manager];
    }
    return self;
}

- (void)loginWithManager:(AFHTTPSessionManager *)manager {
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
                responseObject = @{ @"error": @{@"info": @"Account login info not found."} };
            }

            NSError *error = nil;
            NSDictionary *output = @{};
            if ([responseObject[@"clientlogin"][@"status"] isEqualToString:@"FAIL"]) {
                NSMutableDictionary *errorDict = [responseObject[@"clientlogin"] mutableCopy];
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"message"];
                error = [NSError errorWithDomain:WMFAccountLoginErrorDomain
                                            code:LOGIN_ERROR_API
                                        userInfo:errorDict];
            } else {
                output = responseObject[@"clientlogin"];
            }
            [self finishWithError:error
                      fetchedData:output];
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            //NSLog(@"LOGIN FAIL = %@", error);

            [[MWNetworkActivityIndicatorManager sharedManager] pop];

            [self finishWithError:error
                      fetchedData:nil];
        }];
}

- (NSMutableDictionary *)getAuthManagerParams {
    NSMutableDictionary *params =
        @{
            @"action": @"clientlogin",
            @"username": self.userName,
            @"password": self.password,
            @"loginreturnurl": @"https://www.wikipedia.org",
            @"format": @"json"
        }.mutableCopy;

    if (self.token) {
        params[@"logintoken"] = self.token;
    }

    return params;
}

- (NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse {
    NSMutableDictionary *mutableResponse = [NSMutableDictionary dictionaryWithDictionary:rawResponse];
    // Return the password with the results so it can be added to keychain.
    mutableResponse[@"password"] = self.password;
    return mutableResponse;
}

- (NSError *)getErrorForResult:(NSString *)result {
    // Error types from: http://www.mediawiki.org/wiki/API:Login#Errors
    NSString *errorMessage = [NSString stringWithFormat:@"Unknown login error. Code '%@'", result];
    LoginErrorType errorType = LOGIN_ERROR_UNKNOWN;

    if ([result isEqualToString:@"NoName"]) {
        errorMessage = MWLocalizedString(@"login-name-not-found", nil);
        errorType = LOGIN_ERROR_NAME_REQUIRED;
    } else if ([result isEqualToString:@"Illegal"]) {
        errorMessage = MWLocalizedString(@"login-name-illegal", nil);
        errorType = LOGIN_ERROR_NAME_ILLEGAL;
    } else if ([result isEqualToString:@"NotExists"]) {
        errorMessage = MWLocalizedString(@"login-name-does-not-exist", nil);
        errorType = LOGIN_ERROR_NAME_NOT_FOUND;
    } else if ([result isEqualToString:@"EmptyPass"]) {
        errorMessage = MWLocalizedString(@"login-password-empty", nil);
        errorType = LOGIN_ERROR_PASSWORD_REQUIRED;
    } else if ([result isEqualToString:@"WrongPass"] || [result isEqualToString:@"WrongPluginPass"]) {
        errorMessage = MWLocalizedString(@"login-password-wrong", nil);
        errorType = LOGIN_ERROR_PASSWORD_WRONG;
    } else if ([result isEqualToString:@"Throttled"]) {
        errorMessage = MWLocalizedString(@"login-throttled", nil);
        errorType = LOGIN_ERROR_THROTTLED;
    } else if ([result isEqualToString:@"Blocked"]) {
        errorMessage = MWLocalizedString(@"login-user-blocked", nil);
        errorType = LOGIN_ERROR_BLOCKED;
    }

    return [NSError errorWithDomain:WMFAccountLoginErrorDomain code:errorType userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
}

/*
   -(void)dealloc
   {
    NSLog(@"DEALLOC'ING ACCOUNT LOGIN!");
   }
 */

@end
