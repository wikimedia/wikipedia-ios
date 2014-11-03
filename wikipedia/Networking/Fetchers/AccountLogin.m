//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AccountLogin.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"

@interface AccountLogin()

@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *token;

@end

@implementation AccountLogin

-(instancetype)initAndLoginForDomain: (NSString *)domain
                            userName: (NSString *)userName
                            password: (NSString *)password
                               token: (NSString *)token
                         withManager: (AFHTTPRequestOperationManager *)manager
                  thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
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

- (void)loginWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Account login info not found."}};
        }
        
        //NSLog(@"LOGIN DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Account Login"
                                        code: LOGIN_ERROR_API
                                    userInfo: errorDict];
        }

        NSDictionary *output = @{};
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }

        NSString *result = output[@"login"][@"result"];
        if (![result isEqualToString:@"Success"]) {
            NSMutableDictionary *errorDict = @{}.mutableCopy;
            NSString *errorMessage = [self getErrorMessageForResult:result];
            errorDict[NSLocalizedDescriptionKey] = errorMessage;
            error = [NSError errorWithDomain:@"Account Login" code:LOGIN_ERROR_MISC userInfo:errorDict];
        }

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"LOGIN FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSMutableDictionary *)getParams
{
    NSMutableDictionary *params =
    @{
      @"action": @"login",
      @"lgname": self.userName,
      @"lgpassword": self.password,
      @"format": @"json"
      }.mutableCopy;
    
    if (self.token) {
        params[@"lgtoken"] = self.token;
    }
    
    return params;
}

-(NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    NSMutableDictionary *mutableResponse = [NSMutableDictionary dictionaryWithDictionary:rawResponse];
    // Return the password with the results so it can be added to keychain.
    mutableResponse[@"password"] = self.password;
    return mutableResponse;
}

-(NSString *)getErrorMessageForResult:(NSString *)result
{
    // Error types from: http://www.mediawiki.org/wiki/API:Login#Errors
    NSString *errorMessage = [NSString stringWithFormat:@"Unknown login error. Code '%@'", result];

    if ([result isEqualToString:@"NoName"]) {
        errorMessage = MWLocalizedString(@"login-name-not-found", nil);

    }else if ([result isEqualToString:@"Illegal"]) {
        errorMessage = MWLocalizedString(@"login-name-illegal", nil);

    }else if ([result isEqualToString:@"NotExists"]) {
        errorMessage = MWLocalizedString(@"login-name-does-not-exist", nil);

    }else if ([result isEqualToString:@"EmptyPass"]) {
        errorMessage = MWLocalizedString(@"login-password-empty", nil);

    }else if ([result isEqualToString:@"WrongPass"] || [result isEqualToString:@"WrongPluginPass"]) {
        errorMessage = MWLocalizedString(@"login-password-wrong", nil);

    }else if ([result isEqualToString:@"Throttled"]) {
        errorMessage = MWLocalizedString(@"login-throttled", nil);

    }else if ([result isEqualToString:@"Blocked"]) {
        errorMessage = MWLocalizedString(@"login-user-blocked", nil);
    }
    
    return errorMessage;
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING ACCOUNT LOGIN!");
}
*/

@end
