//  Created by Monte Hurd on 1/16/14.

#import "LoginOp.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSURLRequest+DictionaryRequest.h"

@interface LoginOp()

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *domain;

@end

@implementation LoginOp

-(NSURLRequest *)getRequest
{
    NSMutableDictionary *parameters = [@{
                                         @"action": @"login",
                                         @"lgname": self.userName,
                                         @"lgpassword": self.password,
                                         @"format": @"json"
                                         }mutableCopy];
    

    if (self.token) {
        parameters[@"lgtoken"] = self.token;
    }

    return [NSURLRequest postRequestWithURL: [[SessionSingleton sharedInstance] urlForDomain:self.domain]
                                 parameters: parameters
            ];
}

- (id)initWithUsername: (NSString *)userName
              password: (NSString *)password
                domain: (NSString *)domain
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
{
    self = [super init];
    if (self) {
        self.token = nil;
        self.userName = userName;
        self.password = password;
        self.domain = domain;
        __weak LoginOp *weakSelf = self;
        self.aboutToStart = ^{
            [[MWNetworkActivityIndicatorManager sharedManager] push];
            weakSelf.request = [weakSelf getRequest];
        };
        self.completionBlock = ^(){
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            
            if(weakSelf.isCancelled){
                cancelledBlock(weakSelf.error);
                return;
            }

            // Check for error retrieving section zero data.
            if(weakSelf.jsonRetrieved[@"error"]){
                NSMutableDictionary *errorDict = [weakSelf.jsonRetrieved[@"error"] mutableCopy];
                
                errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
                
                // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                weakSelf.error = [NSError errorWithDomain:@"Login Op" code:001 userInfo:errorDict];
            }

            if (!weakSelf.error) {
                
                //NSLog(@"LoginOp jsonRetrieved = %@", weakSelf.jsonRetrieved);
                
                NSString *result = weakSelf.jsonRetrieved[@"login"][@"result"];
                
                if (![result isEqualToString:@"Success"]) {
                    NSMutableDictionary *errorDict = [@{} mutableCopy];
                    
                    NSString *errorMessage = [weakSelf getErrorMessageForResult:result];
                    
                    errorDict[NSLocalizedDescriptionKey] = errorMessage;
                    
                    // Set error condition so dependent ops don't even start and so the errorBlock below will fire.
                    weakSelf.error = [NSError errorWithDomain:@"Login Op" code:002 userInfo:errorDict];
                }
            }

            if (weakSelf.error) {
                errorBlock(weakSelf.error);
                return;
            }

            //NSDictionary *result = weakSelf.jsonRetrieved;
            NSString *result = weakSelf.jsonRetrieved[@"login"][@"result"];

            completionBlock(result);
        };
    }
    return self;
}

-(NSString *)getErrorMessageForResult:(NSString *)result
{
    // Error types from: http://www.mediawiki.org/wiki/API:Login#Errors
    NSString *errorMessage = [NSString stringWithFormat:@"Unknown login error. Code '%@'", result];

    if ([result isEqualToString:@"NoName"]) {
        errorMessage = NSLocalizedString(@"login-name-not-found", nil);

    }else if ([result isEqualToString:@"Illegal"]) {
        errorMessage = NSLocalizedString(@"login-name-illegal", nil);

    }else if ([result isEqualToString:@"NotExists"]) {
        errorMessage = NSLocalizedString(@"login-name-does-not-exist", nil);

    }else if ([result isEqualToString:@"EmptyPass"]) {
        errorMessage = NSLocalizedString(@"login-password-empty", nil);

    }else if ([result isEqualToString:@"WrongPass"] || [result isEqualToString:@"WrongPluginPass"]) {
        errorMessage = NSLocalizedString(@"login-password-wrong", nil);

    }else if ([result isEqualToString:@"Throttled"]) {
        errorMessage = NSLocalizedString(@"login-throttled", nil);

    }else if ([result isEqualToString:@"Blocked"]) {
        errorMessage = NSLocalizedString(@"login-user-blocked", nil);
    }
    
    return errorMessage;
}

@end
