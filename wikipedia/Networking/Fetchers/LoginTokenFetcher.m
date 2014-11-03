//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LoginTokenFetcher.h"
#import "AFHTTPRequestOperationManager.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+Extras.h"

@interface LoginTokenFetcher()

@property (strong, nonatomic) NSString *domain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *token;

@end

@implementation LoginTokenFetcher

-(instancetype)initAndFetchTokenForDomain: (NSString *)domain
                                 userName: (NSString *)userName
                                 password: (NSString *)password
                              withManager: (AFHTTPRequestOperationManager *)manager
                       thenNotifyDelegate: (id <FetchFinishedDelegate>)delegate
{
    self = [super init];
    if (self) {

        self.domain = domain ? domain : @"";
        self.userName = userName ? userName : @"";
        self.password = password ? password : @"";
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
            responseObject = @{@"error": @{@"info": @"Login token not found."}};
        }
        
        //NSLog(@"LOGIN TOKEN DATA RETRIEVED = %@", responseObject);
        
        // Handle case where response is received, but API reports error.
        NSError *error = nil;
        if (responseObject[@"error"]){
            NSMutableDictionary *errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain: @"Login Token Fetcher"
                                        code: LOGIN_TOKEN_ERROR_API
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

        //NSLog(@"LOGIN TOKEN FAIL = %@", error);

        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError: error
                  fetchedData: nil];
    }];
}

-(NSMutableDictionary *)getParams
{
    return @{
             @"action": @"login",
             @"lgname": self.userName,
             @"lgpassword": self.password,
             @"format": @"json"
             }.mutableCopy;
}

-(NSDictionary *)getSanitizedResponse:(NSDictionary *)rawResponse
{
    if([rawResponse isDict]){
        id login = rawResponse[@"login"];
        if([login isDict]){
            NSString *token = login[@"token"];
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
    NSLog(@"DEALLOC'ING LOGIN TOKEN FETCHER!");
}
*/

@end
