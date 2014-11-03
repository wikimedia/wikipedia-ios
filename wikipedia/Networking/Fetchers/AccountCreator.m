//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AccountCreator.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"
#import "WikipediaAppUtils.h"

@interface AccountCreator()

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

-(instancetype)initAndCreateAccountForUserName: (NSString *)userName
                                      realName: (NSString *)realName
                                        domain: (NSString *)domain
                                      password: (NSString *)password
                                         email: (NSString *)email
                                     captchaId: (NSString *)captchaId
                                   captchaWord: (NSString *)captchaWord
                                         token: (NSString *)token
                                   withManager: (AFHTTPRequestOperationManager *)manager
                            thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
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
        [self creationAccountWithManager: manager];
    }
    return self;
}

- (void)creationAccountWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Account creation data not found."}};
        }
        
        //NSLog(@"ACCT CREATION DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Acct Creation Fetcher"
                                        code: ACCOUNT_CREATION_ERROR_API
                                    userInfo: errorDict];
        }

        NSString *result = @"";
        if (!error) {
            result = [self getSanitizedResultFromResponse:responseObject];

            if ([result isEqualToString:@"NeedCaptcha"]) {
                NSMutableDictionary *errorDict = @{}.mutableCopy;
                
                if (responseObject[@"createaccount"][@"captcha"]) {
                    errorDict[NSLocalizedDescriptionKey] = MWLocalizedString(@"account-creation-captcha-required", nil);
                    
                    // Make the capcha id and url available from the error.
                    errorDict[@"captchaId"] = responseObject[@"createaccount"][@"captcha"][@"id"];
                    errorDict[@"captchaUrl"] = responseObject[@"createaccount"][@"captcha"][@"url"];
                }
                
                error = [NSError errorWithDomain: @"Account Creation Fetcher"
                                            code: ACCOUNT_CREATION_ERROR_NEEDS_CAPTCHA
                                        userInfo: errorDict];
            }

        }

        [self finishWithError: error
                  fetchedData: result];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"ACCT CREATION TOKEN FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSMutableDictionary *)getParams
{
    NSMutableDictionary *params =
    @{
      @"action": @"createaccount",
      @"name": self.userName,
      @"password": self.password,
      @"realname": self.realName,
      @"email": self.email,
      @"reason": ([self.domain isEqualToString:@"test"] ? @"iOS App Account Creation Testing" : @"iOS App Account Creation"),
      @"language": ([self.domain isEqualToString:@"test"] ? @"en" : self.domain),
      @"format": @"json"
      }.mutableCopy;
    
    if (self.token && self.token.length > 0) {
        params[@"token"] = self.token;
    }
    if (self.captchaId && self.captchaId.length > 0) {
        params[@"captchaid"] = self.captchaId;
    }
    if (self.captchaWord && self.captchaWord.length > 0) {
        params[@"captchaword"] = self.captchaWord;
    }
    
    //NSLog(@"params = %@", params);
    return params;
}

-(NSString *)getSanitizedResultFromResponse:(NSDictionary *)rawResponse
{
    if(![rawResponse isDict]) return @"";

    id createaccount = rawResponse[@"createaccount"];

    if(![createaccount isDict]) return @"";

    NSString *result = createaccount[@"result"];
    
    return (result ? result : @"");
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING PAGE HISTORY FETCHER!");
}
*/

@end
