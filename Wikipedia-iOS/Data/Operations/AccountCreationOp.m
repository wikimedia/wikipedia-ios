//  Created by Monte Hurd on 1/16/14.

#import "AccountCreationOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@interface AccountCreationOp()

@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *realName;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *captchaId;
@property (strong, nonatomic) NSString *captchaWord;

@end

@implementation AccountCreationOp

-(NSURLRequest *)getRequest
{
    NSMutableDictionary *parameters = [@{
                                         @"action":     @"createaccount",
                                         @"name":       self.userName,
                                         @"password":   self.password,
                                         @"realname":   self.realName,
                                         @"email":      self.email,
                                         @"reason":     ([self.domain isEqualToString:@"test"])
                                                            ? @"iOS App Account Creation Testing"
                                                            : @"iOS App Account Creation",
                                         @"language":   ([self.domain isEqualToString:@"test"])
                                                            ? @"en"
                                                            : self.domain,
                                         @"format":     @"json"
                                         }mutableCopy];
    
    if (self.token && self.token.length > 0) {
        parameters[@"token"] = self.token;
    }
    if (self.captchaId && self.captchaId.length > 0) {
        parameters[@"captchaid"] = self.captchaId;
    }
    if (self.captchaWord && self.captchaWord.length > 0) {
        parameters[@"captchaword"] = self.captchaWord;
    }

    //NSLog(@"parameters = %@", parameters);
    return [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:self.domain]
                                 parameters: parameters
            ];
}

- (id)initWithDomain: (NSString *) domain
            userName: (NSString *) userName
            password: (NSString *) password
            realName: (NSString *) realName
               email: (NSString *) email
               token: (NSString *) token
           captchaId: (NSString *) captchaId
         captchaWord: (NSString *) captchaWord
     completionBlock: (void (^)(NSString *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {

        self.domain = domain ? domain : @"";
        self.userName = userName ? userName : @"";
        self.password = password ? password : @"";
        self.realName = realName ? realName : @"";
        self.email = email ? email : @"";
        self.token = token ? token : @"";
        self.captchaId = captchaId ? captchaId : @"";
        self.captchaWord = captchaWord ? captchaWord : @"";

        __weak AccountCreationOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
            weakSelf.request = [weakSelf getRequest];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            //NSLog(@"Account Creation Op jsonRetrieved = %@", weakSelf.jsonRetrieved);
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }
            
            // Check for error retrieving section zero data.
            if(weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                NSInteger errorCode = ACCOUNT_CREATION_ERROR_UNKNOWN;
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Account Creation Op" code:errorCode userInfo:errorDict];
            }

            if(weakSelf.jsonRetrieved[@"createaccount"]){
                NSString *createAccountResult = weakSelf.jsonRetrieved[@"createaccount"][@"result"];
                if ([createAccountResult isEqualToString:@"NeedToken"]) {
                    NSMutableDictionary *errorDict = @{}.mutableCopy;
                    
                    errorDict[NSLocalizedDescriptionKey] = NSLocalizedString(@"account-creation-captcha-required", nil);
                    
                    // Make the capcha id and url available from the error.
                    errorDict[@"captchaId"] = weakSelf.jsonRetrieved[@"createaccount"][@"captcha"][@"id"];
                    errorDict[@"captchaUrl"] = weakSelf.jsonRetrieved[@"createaccount"][@"captcha"][@"url"];
                    errorDict[@"token"] = weakSelf.jsonRetrieved[@"createaccount"][@"token"];
                    
                    // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                    weakSelf.error = [NSError errorWithDomain: @"Account Creation Op"
                                                         code: ACCOUNT_CREATION_ERROR_NEEDS_TOKEN
                                                     userInfo: errorDict];
                }
            }
            
            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }
            
            NSString *result = weakSelf.jsonRetrieved[@"createaccount"][@"result"];
            
            completionBlock(result);
        };
    }
    return self;
}

@end
