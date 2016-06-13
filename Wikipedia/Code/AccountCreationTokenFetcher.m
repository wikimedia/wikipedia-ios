//  Created by Monte Hurd on 10/9/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "AccountCreationTokenFetcher.h"
#import <AFNetworking/AFNetworking.h>
#import "MWNetworkActivityIndicatorManager.h"
#import "SessionSingleton.h"
#import "NSObject+WMFExtras.h"

@interface AccountCreationTokenFetcher ()

@property (strong, nonatomic) NSString* domain;
@property (strong, nonatomic) NSString* userName;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) NSString* email;
@property (strong, nonatomic) NSString* token;
@property (assign, nonatomic) BOOL useAuthManager;

@end

@implementation AccountCreationTokenFetcher

- (instancetype)initAndFetchTokenForDomain:(NSString*)domain
                                  userName:(NSString*)userName
                                  password:(NSString*)password
                                     email:(NSString*)email
                            useAuthManager:(BOOL)useAuthManager
                               withManager:(AFHTTPSessionManager*)manager
                        thenNotifyDelegate:(id <FetchFinishedDelegate>)delegate {
    self = [super init];
    if (self) {
        self.domain         = domain ? domain : @"";
        self.userName       = userName ? userName : @"";
        self.password       = password ? password : @"";
        self.email          = email ? email : @"";
        self.token          = @"";
        self.useAuthManager = useAuthManager;

        self.fetchFinishedDelegate = delegate;
        [self fetchTokenWithManager:manager useAuthManager:useAuthManager];
    }
    return self;
}

- (void)fetchTokenWithManager:(AFHTTPSessionManager*)manager useAuthManager:(BOOL)useAuthManager {
    NSURL* url = [[SessionSingleton sharedInstance] urlForLanguage:self.domain];

    NSDictionary* params = useAuthManager ? [self getAuthManagerParams] : [self getLegacyParams];

    [[MWNetworkActivityIndicatorManager sharedManager] push];

    [manager POST:url.absoluteString parameters:params progress:NULL success:^(NSURLSessionDataTask* operation, id responseObject) {
        //NSLog(@"JSON: %@", responseObject);
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        // Fake out an error if non-dictionary response received.
        if (![responseObject isDict]) {
            responseObject = @{@"error": @{@"info": @"Token not found."}};
        }

        // Handle case where response is received, but API reports error.
        NSError* error = nil;
        if (responseObject[@"error"]) {
            NSMutableDictionary* errorDict = [responseObject[@"error"] mutableCopy];
            errorDict[NSLocalizedDescriptionKey] = errorDict[@"info"];
            error = [NSError errorWithDomain:@"Acct Creation Token Fetcher"
                                        code:ACCOUNT_CREATION_TOKEN_ERROR_API
                                    userInfo:errorDict];
        }


        if (useAuthManager) {
            self.token = responseObject[@"query"][@"tokens"][@"createaccounttoken"];
            [self finishWithError:error
                      fetchedData:self.token];
        } else {
            NSDictionary* output = @{};
            if (!error) {
                output = [self getSanitizedResponse:responseObject];
            }

            self.token = output[@"token"] ? output[@"token"] : @"";

            [self finishWithError:error
                      fetchedData:output];
        }
    } failure:^(NSURLSessionDataTask* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];

        [self finishWithError:error
                  fetchedData:nil];
    }];
}

- (NSMutableDictionary*)getLegacyParams {
    return @{
               @"action": @"createaccount",
               @"name": self.userName,
               @"password": self.password,
               @"language": ([self.domain isEqualToString:@"test"] ? @"en" : self.domain),
               @"format": @"json"
    }.mutableCopy;
}

- (NSMutableDictionary*)getAuthManagerParams {
    return @{
               @"action": @"query",
               @"meta": @"tokens",
               @"type": @"createaccount",
               @"format": @"json"
    }.mutableCopy;
}

- (NSDictionary*)getSanitizedResponse:(NSDictionary*)rawResponse {
    if ([rawResponse isDict]) {
        id createaccount = rawResponse[@"createaccount"];
        if ([createaccount isDict]) {
            NSString* token = createaccount[@"token"];
            if (token) {
                return @{@"token": token};
            }
        }
    }
    return @{};
}

@end
