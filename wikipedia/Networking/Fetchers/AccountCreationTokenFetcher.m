//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AccountCreationTokenFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@interface AccountCreationTokenFetcher()

@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *token;

@end

@implementation AccountCreationTokenFetcher

-(instancetype)initAndFetchTokenForDomain: (NSString *)domain
                                 userName: (NSString *)userName
                                 password: (NSString *)password
                                    email: (NSString *)email
                              withManager: (AFHTTPRequestOperationManager *)manager
                       thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {

        self.domain = domain ? domain : @"";
        self.userName = userName ? userName : @"";
        self.password = password ? password : @"";
        self.email = email ? email : @"";
        self.token = @"";

        self.fetchFinishedDelegate = delegate;
        [self fetchTokenWithManager:manager];
    }
    return self;
}

- (void)fetchTokenWithManager: (AFHTTPRequestOperationManager *)manager
{
    NSURL *url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

    NSDictionary *params = [self getParams];
    
    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if(![responseObject isDict]){
            responseObject = @{@"error": @{@"info": @"Token not found."}};
        }
        
        //NSLog(@"ACCT CREATION TOKEN DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Acct Creation Token Fetcher"
                                        code: ACCOUNT_CREATION_TOKEN_ERROR_API
                                    userInfo: errorDict];
        }

        NSDictionary *output = @{};
        if (!error) {
            output = [self getSanitizedResponse:responseObject];
        }
        
        self.token = output[@"token"] ? output[@"token"] : @"";

        [self finishWithError: error
                  fetchedData: output];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        //NSLog(@"ACCT CREATION TOKEN FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSMutableDictionary *)getParams
{
    return @{
             @"action": @"createaccount",
             @"name": self.userName,
             @"password": self.password,
             @"language": ([self.domain isEqualToString:@"test"] ? @"en" : self.domain),
             @"format": @"json"
             }.mutableCopy;
}

-(NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    if([rawResponse isDict]){
        id createaccount = rawResponse[@"createaccount"];
        if([createaccount isDict]){
            NSString *token = createaccount[@"token"];
            if (token) {
                return @{@"token": token};
            }
        }
    }
    return @{};
}

/*
-(void)dealloc
{
    NSLog(@"DEALLOC'ING ACCT CREATION TOKEN FETCHER!");
}
*/

@end
